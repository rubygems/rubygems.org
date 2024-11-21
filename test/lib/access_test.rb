require "test_helper"

class AccessTest < ActiveSupport::TestCase
  context "roles are correctly sequenced" do
    should "be in the correct order" do
      assert_operator Access::OWNER, :>, Access::ADMIN
      assert_operator Access::ADMIN, :>, Access::MAINTAINER
    end
  end

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
      assert_equal (Access::OWNER..), Access.with_minimum_role("owner")
      assert_equal (Access::ADMIN..), Access.with_minimum_role("admin")
      assert_equal (Access::MAINTAINER..), Access.with_minimum_role("maintainer")
    end
  end
end
