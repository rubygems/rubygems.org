require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should_have_many :rubygems

  should "create api key" do
    user = Factory(:user)
    assert_not_nil user.api_key
  end
end
