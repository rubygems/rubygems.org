require "test_helper"

class AccessTest < ActiveSupport::TestCase
  context ".role_for_flag" do
    should "return the role for a given permission flag" do
      assert_equal "owner", Access.role_for_flag(Access::OWNER)
    end

    context "when the permission flag does not exist" do
      should "raise an error" do
        assert_raises(ArgumentError) { Access.role_for_flag(999) }
      end
    end
  end

  context ".flag_for_role" do
    should "return the role for a given permission flag" do
      assert_equal Access::OWNER, Access.flag_for_role("owner")
    end

    should "cast the given input into the correct type" do
      assert_equal Access::OWNER, Access.flag_for_role(:owner)
    end

    context "when the role does not exist" do
      should "raise an error" do
        assert_raises(KeyError) { Access.flag_for_role("unknown") }
      end
    end
  end
end
