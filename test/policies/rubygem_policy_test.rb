require "test_helper"

class RubygemPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @maintainer = create(:user, handle: "maintainer")
    @rubygem = create(:rubygem, owners: [@owner], maintainers: [@maintainer])

    @org_owner = create(:user, handle: "org_owner")
    @org_admin = create(:user, handle: "org_admin")
    @org_maintainer = create(:user, handle: "org_maintainer")
    @organization = create(
      :organization,
      owners: [@org_owner],
      maintainers: [@org_maintainer],
      admins: [@org_admin]
    )
    @org_rubygem = create(
      :rubygem,
      organization: @organization,
      owners: [@owner],
      maintainers: [@maintainer]
    )

    @user = create(:user, handle: "user")
  end

  def policy!(user)
    Pundit.policy!(user, @rubygem)
  end

  def org_policy!(user)
    Pundit.policy!(user, @org_rubygem)
  end

  context "#create?" do
    should "allow users" do
      assert_authorized policy!(@owner), :create?
      assert_authorized policy!(@user), :create?
      refute_authorized policy!(nil), :create?
    end
  end

  context "#configure_oidc?" do
    should "only allow the owner" do
      assert_authorized policy!(@owner), :configure_oidc?
      refute_authorized policy!(@user), :configure_oidc?
      refute_authorized policy!(nil), :configure_oidc?
    end

    should "only allow owners, org owners and admins" do
      assert_authorized org_policy!(@org_owner), :configure_oidc?
      assert_authorized org_policy!(@org_admin), :configure_oidc?
      assert_authorized org_policy!(@owner), :configure_oidc?

      refute_authorized org_policy!(@org_maintainer), :configure_oidc?
      refute_authorized org_policy!(@user), :configure_oidc?
      refute_authorized org_policy!(nil), :configure_oidc?
    end
  end

  context "#show_events?" do
    should "only allow the owner and maintainer" do
      assert_authorized policy!(@owner), :show_events?
      assert_authorized policy!(@maintainer), :show_events?
      refute_authorized policy!(@user), :show_events?
      refute_authorized policy!(nil), :show_events?
    end

    should "only allow anyone with access to the gem" do
      assert_authorized org_policy!(@org_owner), :show_events?
      assert_authorized org_policy!(@org_admin), :show_events?
      assert_authorized org_policy!(@org_maintainer), :show_events?
      assert_authorized org_policy!(@owner), :show_events?
      assert_authorized org_policy!(@maintainer), :show_events?

      refute_authorized org_policy!(@user), :show_events?
      refute_authorized org_policy!(nil), :show_events?
    end
  end

  context "#configure_trusted_publishers?" do
    should "only allow the owner" do
      assert_authorized policy!(@owner), :configure_trusted_publishers?
      refute_authorized policy!(@maintainer), :configure_trusted_publishers?
      refute_authorized policy!(@user), :configure_trusted_publishers?
      refute_authorized policy!(nil), :configure_trusted_publishers?
    end

    should "only allow owners, org owners and admins" do
      assert_authorized org_policy!(@org_owner), :configure_trusted_publishers?
      assert_authorized org_policy!(@org_admin), :configure_trusted_publishers?
      assert_authorized org_policy!(@owner), :configure_trusted_publishers?

      refute_authorized org_policy!(@org_maintainer), :configure_trusted_publishers?
      refute_authorized org_policy!(@maintainer), :configure_trusted_publishers?
      refute_authorized org_policy!(@user), :configure_trusted_publishers?
      refute_authorized org_policy!(nil), :configure_trusted_publishers?
    end
  end

  context "#show_unconfirmed_ownerships?" do
    should "only allow the owner" do
      assert_authorized policy!(@owner), :show_unconfirmed_ownerships?
      refute_authorized policy!(@maintainer), :show_unconfirmed_ownerships?
      refute_authorized policy!(@user), :show_unconfirmed_ownerships?
      refute_authorized policy!(nil), :show_unconfirmed_ownerships?
    end

    should "only allow owners, org owners and admins" do
      assert_authorized org_policy!(@org_owner), :show_unconfirmed_ownerships?
      assert_authorized org_policy!(@org_admin), :show_unconfirmed_ownerships?
      assert_authorized org_policy!(@owner), :show_unconfirmed_ownerships?

      refute_authorized org_policy!(@org_maintainer), :show_unconfirmed_ownerships?
      refute_authorized org_policy!(@user), :show_unconfirmed_ownerships?
      refute_authorized org_policy!(nil), :show_unconfirmed_ownerships?
    end
  end

  context "#add_owner?" do
    should "only allow the owner" do
      assert_authorized policy!(@owner), :add_owner?
      refute_authorized policy!(@maintainer), :add_owner?
      refute_authorized policy!(@user), :add_owner?
      refute_authorized policy!(nil), :add_owner?
    end
  end

  context "#update_owner?" do
    should "only allow the owner" do
      assert_authorized policy!(@owner), :update_owner?
      refute_authorized policy!(@maintainer), :update_owner?
      refute_authorized policy!(@user), :update_owner?
      refute_authorized policy!(nil), :update_owner?
    end
  end

  context "#remove_owner?" do
    should "only allow the owner" do
      assert_authorized policy!(@owner), :remove_owner?
      refute_authorized policy!(@maintainer), :remove_owner?
      refute_authorized policy!(@user), :remove_owner?
      refute_authorized policy!(nil), :remove_owner?
    end
  end
end
