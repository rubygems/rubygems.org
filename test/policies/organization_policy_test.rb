require "test_helper"
class OrganisationPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user)
    @admin = create(:user)
    @maintainer = create(:user)
    @guest = create(:user)
    @organization = create(:organization, owners: [@owner], admins: [@admin], maintainers: [@maintainer])
  end

  def policy!(user)
    Pundit.policy!(user, @organization)
  end

  context "#update?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :update?
      assert_authorized @admin, :update?
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
      assert_authorized @admin, :remove_gem?
      refute_authorized @maintainer, :remove_gem?
      refute_authorized @guest, :remove_gem?
    end
  end

  context "#add_membership?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :add_membership?
      assert_authorized @admin, :add_membership?
      refute_authorized @maintainer, :add_membership?
      refute_authorized @guest, :add_membership?
    end
  end

  context "#update_membership?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :update_membership?
      assert_authorized @admin, :update_membership?
      refute_authorized @maintainer, :update_membership?
      refute_authorized @guest, :update_membership?
    end
  end

  context "#remove_membership?" do
    should "only be authorized if the user is an owner" do
      assert_authorized @owner, :remove_membership?
      assert_authorized @admin, :remove_membership?
      refute_authorized @maintainer, :remove_membership?
      refute_authorized @guest, :remove_membership?
    end
  end

  context "#show_membership?" do
    should "only be authorized if the user is an owner or maintainer" do
      assert_authorized @owner, :show_membership?
      assert_authorized @admin, :show_membership?
      assert_authorized @maintainer, :show_membership?
      refute_authorized @guest, :show_membership?
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
