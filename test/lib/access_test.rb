require "test_helper"

class AccessTest < ActiveSupport::TestCase
  context ".label_for_role" do
    should "return the correct label for the given role" do
      assert_equal "Owner", Access.label_for_role(:owner)
    end

    should "cast the given input into the correct type" do
      assert_equal "Owner", Access.label_for_role("owner")
    end

    should "return nil when the role is unknown" do
      assert_nil Access.label_for_role(:unknown)
    end
  end

  context ".role_for_permission" do
    should "return the role for a given permission flag" do
      assert_equal :owner, Access.role_for_permission(Access::OWNER)
    end

    should "when the permission flag does not exist" do
      assert_nil Access.role_for_permission(999)
    end
  end

  context ".label_for_role_flag" do
    should "return the label for the role flag" do
      assert_equal "Owner", Access.label_for_role_flag(Access::OWNER)
    end

    context "when the role flag is invalid" do
      should "return nil" do
        assert_nil Access.label_for_role_flag(999)
      end
    end

    context "when the input is not a string" do
      should "raise an ArgumentError" do
        assert_raises(ArgumentError) { Access.label_for_role_flag("owner") }
      end
    end
  end

  context ".options" do
    should "return an array of options" do
      assert_equal [["Maintainer", :maintainer], ["Owner", :owner]], Access.options
    end
  end
end
