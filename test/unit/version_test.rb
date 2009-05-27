require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_valid Factory.build(:version)
  end
 
end
