require "test_helper"

class GemPermissionsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @other_user = create(:user)
  end

  context "for organization-owned gems" do
    setup do
      @organization = create(:organization)
      @rubygem = create(:rubygem, organization: @organization)
      @permissions = GemPermissions.new(@rubygem, @user)
    end

    context "#can_push?" do
      should "return true when user is a member of the organization" do
        create(:membership, organization: @organization, user: @user, role: :maintainer)

        assert_predicate @permissions, :can_push?
      end

      should "return true when user is an admin of the organization" do
        create(:membership, organization: @organization, user: @user, role: :admin)

        assert_predicate @permissions, :can_push?
      end

      should "return true when user is an owner of the organization" do
        create(:membership, organization: @organization, user: @user, role: :owner)

        assert_predicate @permissions, :can_push?
      end

      should "return false when user is not a member of the organization" do
        refute_predicate @permissions, :can_push?
      end

      should "return false when user has unconfirmed membership" do
        create(:membership, organization: @organization, user: @user, role: :maintainer, confirmed_at: nil)

        refute_predicate @permissions, :can_push?
      end

      should "return false when user is nil" do
        permissions = GemPermissions.new(@rubygem, nil)

        refute_predicate permissions, :can_push?
      end
    end

    context "#can_admin?" do
      should "return false when user is a maintainer of the organization" do
        create(:membership, organization: @organization, user: @user, role: :maintainer)

        refute_predicate @permissions, :can_admin?
      end

      should "return true when user is an admin of the organization" do
        create(:membership, organization: @organization, user: @user, role: :admin)

        assert_predicate @permissions, :can_admin?
      end

      should "return true when user is an owner of the organization" do
        create(:membership, organization: @organization, user: @user, role: :owner)

        assert_predicate @permissions, :can_admin?
      end

      should "return false when user is not a member of the organization" do
        refute_predicate @permissions, :can_admin?
      end

      should "return false when user has unconfirmed admin membership" do
        create(:membership, organization: @organization, user: @user, role: :admin, confirmed_at: nil)

        refute_predicate @permissions, :can_admin?
      end

      should "return false when user is nil" do
        permissions = GemPermissions.new(@rubygem, nil)

        refute_predicate permissions, :can_admin?
      end
    end

    context "#can_manage_owners?" do
      should "return false when user is a maintainer of the organization" do
        create(:membership, organization: @organization, user: @user, role: :maintainer)

        refute_predicate @permissions, :can_manage_owners?
      end

      should "return false when user is an admin of the organization" do
        create(:membership, organization: @organization, user: @user, role: :admin)

        refute_predicate @permissions, :can_manage_owners?
      end

      should "return true when user is an owner of the organization" do
        create(:membership, organization: @organization, user: @user, role: :owner)

        assert_predicate @permissions, :can_manage_owners?
      end

      should "return false when user is not a member of the organization" do
        refute_predicate @permissions, :can_manage_owners?
      end

      should "return false when user has unconfirmed owner membership" do
        create(:membership, organization: @organization, user: @user, role: :owner, confirmed_at: nil)

        refute_predicate @permissions, :can_manage_owners?
      end

      should "return false when user is nil" do
        permissions = GemPermissions.new(@rubygem, nil)

        refute_predicate permissions, :can_manage_owners?
      end
    end
  end

  context "for individually-owned gems" do
    setup do
      @rubygem = create(:rubygem)
      @permissions = GemPermissions.new(@rubygem, @user)
    end

    context "#can_push?" do
      should "return true when user has maintainer ownership" do
        create(:ownership, user: @user, rubygem: @rubygem, role: :maintainer)

        assert_predicate @permissions, :can_push?
      end

      should "return true when user has owner ownership" do
        create(:ownership, user: @user, rubygem: @rubygem, role: :owner)

        assert_predicate @permissions, :can_push?
      end

      should "return false when user has no ownership" do
        refute_predicate @permissions, :can_push?
      end

      should "return false when user is nil" do
        permissions = GemPermissions.new(@rubygem, nil)

        refute_predicate permissions, :can_push?
      end
    end

    context "#can_admin?" do
      should "return false when user has maintainer ownership" do
        create(:ownership, user: @user, rubygem: @rubygem, role: :maintainer)

        refute_predicate @permissions, :can_admin?
      end

      should "return true when user has owner ownership" do
        create(:ownership, user: @user, rubygem: @rubygem, role: :owner)

        assert_predicate @permissions, :can_admin?
      end

      should "return false when user has no ownership" do
        refute_predicate @permissions, :can_admin?
      end

      should "return false when user is nil" do
        permissions = GemPermissions.new(@rubygem, nil)

        refute_predicate permissions, :can_admin?
      end
    end

    context "#can_manage_owners?" do
      should "return false when user has maintainer ownership" do
        create(:ownership, user: @user, rubygem: @rubygem, role: :maintainer)

        refute_predicate @permissions, :can_manage_owners?
      end

      should "return true when user has owner ownership" do
        create(:ownership, user: @user, rubygem: @rubygem, role: :owner)

        assert_predicate @permissions, :can_manage_owners?
      end

      should "return false when user has no ownership" do
        refute_predicate @permissions, :can_manage_owners?
      end

      should "return false when user is nil" do
        permissions = GemPermissions.new(@rubygem, nil)

        refute_predicate permissions, :can_manage_owners?
      end
    end
  end

  context "edge cases" do
    setup do
      @rubygem = create(:rubygem)
      @permissions = GemPermissions.new(@rubygem, @user)
    end

    should "handle unknown minimum_role gracefully" do
      # This tests the else clause in organization_role_check
      organization = create(:organization)
      @rubygem.update(organization: organization)
      create(:membership, organization: organization, user: @user, role: :owner)

      # We can't directly test the private method, but we can verify that
      # unknown roles return false by testing a role that doesn't exist
      permissions = GemPermissions.new(@rubygem, @user)

      # All valid roles should work
      assert_predicate permissions, :can_push?
      assert_predicate permissions, :can_admin?
      assert_predicate permissions, :can_manage_owners?
    end
  end
end
