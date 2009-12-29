require File.dirname(__FILE__) + '/../test_helper'

class WebHookTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_valid Factory.build(:web_hook)
  end
 
end
