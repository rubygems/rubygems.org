require File.dirname(__FILE__) + '/../test_helper'

class RubygemTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_valid Factory.build(:rubygem)
  end
 
end
