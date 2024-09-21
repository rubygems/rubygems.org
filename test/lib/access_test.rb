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

  context ".with_minimum_role" do
    should "return the range of roles for a given permission flag" do
      assert_equal Range.new(Access::OWNER, nil), Access.with_minimum_role("owner")
      refute_includes Access.with_minimum_role("owner"), Access::MAINTAINER
      assert_includes Access.with_minimum_role("owner"), Access::OWNER
      assert_includes Access.with_minimum_role("owner"), Access::ADMIN
    end
  end
end
