require File.dirname(__FILE__) + '/../test_helper'

class RequirementTest < ActiveSupport::TestCase
  should_belong_to :version
  should_belong_to :dependency

  context "with requirement" do
    setup do
      @requirement = Factory.build(:requirement)
    end

    should "be valid with factory" do
      assert_valid @requirement
    end
  end

end
