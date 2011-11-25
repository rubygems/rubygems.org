require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  should belong_to :rubygem
  should belong_to :user

  context "with a linkset" do
    setup do
      @subscription = FactoryGirl.create(:subscription)
    end

    subject { @subscription }

    should validate_uniqueness_of(:rubygem_id).scoped_to(:user_id)

    should "be valid with factory" do
      assert_valid @subscription
    end
  end
end
