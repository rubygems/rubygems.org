require File.dirname(__FILE__) + '/../test_helper'

class DependencyTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_valid Factory.build(:dependency)
  end
 
end
