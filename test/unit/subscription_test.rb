require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  should belong_to :rubygem
  should belong_to :user
  should validate_uniqueness_of(:rubygem_id).scoped_to(:user_id)
  should validate_presence_of(:rubygem)
  should validate_presence_of(:user)

  should "be valid with factory" do
    assert_predicate build(:ownership), :valid?
  end
end
