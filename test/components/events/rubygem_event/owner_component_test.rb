require "test_helper"
require "phlex/testing/rails/view_helper"

class Events::RubygemEvent::OwnerComponentTest < ActiveSupport::TestCase
  include Phlex::Testing::Rails::ViewHelper
  include Capybara::Minitest::Assertions

  def render(...)
    response = super
    @page = Capybara.string(response)
  end

  attr_reader :page

  def preview(path, scenario: :default, **params)
    preview = Lookbook::Engine.previews.find_by_path(path)
    render_args = preview.render_args(scenario, params:)
    render_args.fetch(:component)
  end

  test "owner added" do
    user = create(:user, handle: "Owner")
    render preview("events/rubygem_event/owner/added", user:)

    assert_text "New owner added: OwnerAuthorized by: Authorizer", exact: true
    assert_link user.handle, href: view_context.profile_path(user.display_id)
    assert_link "Authorizer", href: view_context.profile_path(user.display_id)

    render preview("events/rubygem_event/owner/added", scenario: :without_actor)

    assert_text "New owner added: OwnerAuthorized by: Authorizer", exact: true
    assert_link user.handle, href: view_context.profile_path(user.display_id)
    assert_no_link "Authorizer"

    render preview("events/rubygem_event/owner/added", scenario: :without_authorizer)

    assert_text "New owner added: Owner", exact: true
    assert_link user.handle, href: view_context.profile_path(user.display_id)
  end

  test "owner added with a deleted user" do
    user = create(:user, handle: "Owner")
    component = preview("events/rubygem_event/owner/added", user:)
    user.destroy!
    render component

    assert_text "New owner added: OwnerAuthorized by: Authorizer", exact: true
    assert_no_link "Owner"
  end
end
