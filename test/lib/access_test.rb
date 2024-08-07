require "test_helper"

class AccessTest < ActiveSupport::TestCase
  context ".label_for_role" do
    should "return the correct label for the given role" do
      assert_equal "Owner", Access.label_for_role(:owner)
    end

    should "cast the given input into the correct type" do
      assert_equal "Owner", Access.label_for_role(:owner)
    end

    context "when the role is unknown" do
      should "return nil" do
        assert_nil Access.label_for_role(:unknown)
      end
    end
  end

  context ".role_for_flag" do
    should "return the role for a given permission flag" do
      assert_equal "owner", Access.role_for_flag(Access::OWNER)
    end

    context "when the permission flag does not exist" do
      should "reutrn nil" do
        assert_nil Access.role_for_flag(999)
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
      should "return nil" do
        assert_nil Access.flag_for_role(:unknown)
      end
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
  end

  context ".options" do
    should "return an array of options" do
      assert_equal [%w[Maintainer maintainer], %w[Owner owner]], Access.options
    end
  end
end
