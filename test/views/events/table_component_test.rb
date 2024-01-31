require "test_helper"
require "phlex/testing/rails/view_helper"

class Events::TableComponentTest < ActiveSupport::TestCase
  include Phlex::Testing::Rails::ViewHelper

  class TestEvent
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON

    def self.belongs_to(...) = nil
    def has_attribute?(name) = respond_to?(name) # rubocop:disable Naming/PredicateName

    attribute :additional
    attribute :created_at, :datetime, default: -> { Time.zone.now }
    attribute :geoip_info, Types::JsonDeserializable.new(GeoipInfo)

    include Events::Tags
  end

  class UserTestEvent < TestEvent
    attribute :user_id, :integer
    def user = User.where(id: user_id).first
  end

  teardown do
    TestEvent.tags.clear
  end

  def table(security_events = page([]), stubs: nil)
    Events::TableComponent.new(security_events:).tap do |component|
      component.stubs(stubs) if stubs
    end
  end

  def render(...)
    response = super
    Capybara.string(response)
  end

  def page(array, page: 0, per: 10)
    Kaminari.paginate_array(array).page(page).per(per)
  end

  test "renders an empty view" do
    page = render table

    page.assert_text "No entries found"
  end

  test "renders an unknown event" do
    page = render table(page([TestEvent.new(tag: "unknown:other")]))

    page.assert_text "Displaying 1 entry"
    page.assert_text "unknown:other"
  end

  test "renders redacted additional info when user_id does not match" do
    tag = TestEvent.define_event "user2:created"

    user = create(:user)

    page = render table(page([
                               UserTestEvent.new(tag: tag, user_id: user.id + 1, geoip_info: build(:geoip_info), additional: {
                                                   user_agent_info: build(:events_user_agent_info)
                                                 })
                             ]), stubs: { current_user: user })

    page.assert_text "Displaying 1 entry"
    page.assert_text "user2:created"
    page.assert_text "Redacted"
    page.assert_no_text "Buffalo, NY, US"
    page.assert_no_text "installer (implementation on system)"
  end

  test "renders additional info when user_id matches" do
    tag = TestEvent.define_event "user:created2"

    user = create(:user)

    page = render table(page([
                               UserTestEvent.new(tag: tag, user_id: user.id, geoip_info: build(:geoip_info), additional: {
                                                   user_agent_info: build(:events_user_agent_info)
                                                 })
                             ]), stubs: { current_user: user })

    page.assert_text "Displaying 1 entry"
    page.assert_text "user:created"
    page.assert_text "Buffalo, NY, US"
    page.assert_text "installer (implementation on system)"
  end
end
