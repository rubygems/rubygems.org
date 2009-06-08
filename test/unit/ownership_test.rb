require 'test_helper'

class OwnershipTest < ActiveSupport::TestCase

  should "be valid with factory" do
    assert_valid Factory.build(:ownership)
  end

  should_belong_to :rubygem
  should_have_index :rubygem_id
  should_belong_to :user
  should_have_index :user_id

  should "create token" do
    assert_not_nil Factory(:ownership).token
  end
 
end
