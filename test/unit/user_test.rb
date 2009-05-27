require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  should_have_many :rubygems

end
