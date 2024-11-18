require "test_helper"
class OrganizationPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @admin = create(:user, handle: "admin")
    @maintainer = create(:user, handle: "maintainer")
    @guest = create(:user)
    @organization = create(:organization, owners: [@owner], admins: [@admin], maintainers: [@maintainer])
  end

  def policy!(user)
    Pundit.policy!(user, @organization)
  end

  context "#show?" do
    should "be authorized for all users" do
      assert_authorized @owner, :show?
      assert_authorized @admin, :show?
      assert_authorized @maintainer, :show?
      assert_authorized @guest, :show?
    end
  end

  context "#create?" do
    should "be authorized for all users" do
      assert_authorized @owner, :create?
      assert_authorized @admin, :create?
      assert_authorized @maintainer, :create?
      assert_authorized @guest, :create?
    end
  end

  context "#destroy?" do
    should "be disallowed for all users until further development" do
      refute_authorized @owner, :destroy?
      refute_authorized @admin, :destroy?
      refute_authorized @maintainer, :destroy?
      refute_authorized @guest, :destroy?
    end
  end

  context "#update?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :update?

      refute_authorized @admin, :update?
      refute_authorized @maintainer, :update?
      refute_authorized @guest, :update?
    end
  end

  context "add_gem?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :add_gem?
      assert_authorized @admin, :add_gem?

      refute_authorized @maintainer, :add_gem?
      refute_authorized @guest, :add_gem?
    end
  end

  context "#remove_gem?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :remove_gem?

      refute_authorized @admin, :remove_gem?
      refute_authorized @maintainer, :remove_gem?
      refute_authorized @guest, :remove_gem?
    end
  end

  context "#manage_memberships?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :manage_memberships?
      assert_authorized @admin, :manage_memberships?

      refute_authorized @maintainer, :manage_memberships?
      refute_authorized @guest, :manage_memberships?
    end
  end

  context "#list_memberships?" do
    should "only be authorized if the user is an owner or maintainer" do
      assert_authorized @owner, :list_memberships?
      assert_authorized @admin, :list_memberships?
      assert_authorized @maintainer, :list_memberships?

      refute_authorized @guest, :list_memberships?
    end
  end
end
