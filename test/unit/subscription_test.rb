require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  def setup
    super
    WebMock.stub_request(:any, /.*localhost:9200.*/).to_return(:body => '{}', :status => 200)
  end

  should belong_to :rubygem
  should belong_to :user

  context "with a linkset" do
    setup do
      @subscription = create(:subscription)
    end

    subject { @subscription }

    should validate_uniqueness_of(:rubygem_id).scoped_to(:user_id)

    should "be valid with factory" do
      assert @subscription.valid?
    end
  end
end
