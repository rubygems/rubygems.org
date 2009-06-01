require File.dirname(__FILE__) + '/../test_helper'

class LinksetTest < ActiveSupport::TestCase
  should_belong_to :rubygem

  should "be valid with factory" do
    assert_valid Factory.build(:linkset)
  end
end
