require "test_helper"

class RubygemPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @maintainer = create(:user, handle: "maintainer")
    @rubygem = create(:rubygem, owners: [@owner], maintainers: [@maintainer])
    @user = create(:user, handle: "user")
  end

  def policy!(user)
    Pundit.policy!(user, @rubygem)
  end

  context "#configure_oidc?" do
    should "only allow the owner" do
      assert_authorized @owner, :configure_oidc?
      refute_authorized @user, :configure_oidc?
      refute_authorized nil, :configure_oidc?
    end
  end

  context "#manage_adoption?" do
    should "only allow the owner" do
      assert_authorized @owner, :manage_adoption?
      refute_authorized @user, :manage_adoption?
      refute_authorized nil, :manage_adoption?
    end
  end

  context "#request_ownership?" do
    should "be true if the gem has ownership calls" do
      create(:ownership_call, rubygem: @rubygem, user: @owner)

      assert_authorized @user, :request_ownership?
    end

    should "be false if the gem has more than 10,000 downloads" do
      @rubygem = create(:rubygem, owners: [@owner], downloads: 10_001)
      create(:version, rubygem: @rubygem, created_at: 2.years.ago)

      assert_operator @rubygem.downloads, :>, RubygemPolicy::ABANDONED_DOWNLOADS_MAX
      refute_authorized @user, :request_ownership?
    end

    should "be false if the gem has no versions" do
      assert_empty @rubygem.versions
      refute_authorized @user, :request_ownership?
    end

    should "be false if the gem has a version newer than 1 year" do
      create(:version, rubygem: @rubygem, created_at: 11.months.ago)

      refute_authorized @user, :request_ownership?
    end

    should "be true if the gem's latest version is older than 1 year and less than 10,000 downloads" do
      create(:version, rubygem: @rubygem, created_at: 2.years.ago)

      assert_authorized @user, :request_ownership?
    end
  end

  context "#close_ownership_requests" do
    should "only allow the owner to close ownership requests" do
      assert_authorized @owner, :close_ownership_requests?
      refute_authorized @maintainer, :close_ownership_requests?
      refute_authorized @user, :close_ownership_requests?
    end
  end

  context "#show_adoption?" do
    should "be true if the gem is owned by the user" do
      assert_authorized @owner, :show_adoption?
      refute_authorized @maintainer, :show_adoption?
    end

    should "be true if the rubygem is adoptable" do
      create(:version, rubygem: @rubygem, created_at: 2.years.ago)

      assert_authorized @user, :show_adoption?
    end
  end

  context "#show_events?" do
    should "only allow the owner" do
      assert_authorized @owner, :show_events?
      assert_authorized @maintainer, :show_events?
      refute_authorized @user, :show_events?
      refute_authorized nil, :show_events?
    end
  end

  context "#configure_trusted_publishers?" do
    should "only allow the owner" do
      assert_authorized @owner, :configure_trusted_publishers?
      refute_authorized @maintainer, :configure_trusted_publishers?
      refute_authorized @user, :configure_trusted_publishers?
      refute_authorized nil, :configure_trusted_publishers?
    end
  end

  context "#show_unconfirmed_ownerships?" do
    should "only allow the owner" do
      assert_authorized @owner, :show_unconfirmed_ownerships?
      refute_authorized @maintainer, :show_unconfirmed_ownerships?
      refute_authorized @user, :show_unconfirmed_ownerships?
      refute_authorized nil, :show_unconfirmed_ownerships?
    end
  end

  context "#add_owner?" do
    should "only allow the owner" do
      assert_authorized @owner, :add_owner?
      refute_authorized @maintainer, :add_owner?
      refute_authorized @user, :add_owner?
      refute_authorized nil, :add_owner?
    end
  end

  context "#update_owner?" do
    should "only allow the owner" do
      assert_authorized @owner, :update_owner?
      refute_authorized @maintainer, :update_owner?
      refute_authorized @user, :update_owner?
      refute_authorized nil, :update_owner?
    end
  end

  context "#remove_owner?" do
    should "only allow the owner" do
      assert_authorized @owner, :remove_owner?
      refute_authorized @maintainer, :remove_owner?
      refute_authorized @user, :remove_owner?
      refute_authorized nil, :remove_owner?
    end
  end
end
