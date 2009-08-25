require File.dirname(__FILE__) + '/../test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_belong_to :user

  context "with a linkset" do
    setup do
      @subscription = Factory.create(:subscription)
    end

    subject { @subscription }

    should_validate_uniqueness_of :rubygem_id, :scoped_to => :user_id

    should "be valid with factory" do
      assert_valid @subscription
    end
  end
end
