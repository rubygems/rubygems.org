require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should_have_many :rubygems, :through => :ownerships
  should_have_many :ownerships

  context "with a user" do
    setup do
      @user = Factory(:user)
    end

    should "create api key" do
      assert_not_nil @user.api_key
    end

    should "only return approved rubygems" do
      my_rubygem = Factory(:rubygem)
      other_rubygem = Factory(:rubygem)
      Factory(:ownership, :user => @user, :rubygem => my_rubygem, :approved => true)
      Factory(:ownership, :user => @user, :rubygem => other_rubygem, :approved => false)

      assert_equal [my_rubygem], @user.rubygems
    end
  end
end
