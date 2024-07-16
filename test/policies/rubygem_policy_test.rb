require "test_helper"

class RubygemPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @rubygem = create(:rubygem, owners: [@owner])
    @user = create(:user, handle: "user")
  end

  def policy!(user)
    Pundit.policy!(user, @rubygem)
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

  context "#show_adoption?" do
    should "be true if the gem is owned by the user" do
      assert_authorized @owner, :show_adoption?
    end

    should "be true if the rubygem is adoptable" do
      create(:version, rubygem: @rubygem, created_at: 2.years.ago)

      assert_authorized @user, :show_adoption?
    end
  end

  context "#show_events?" do
    should "only allow the owner" do
      assert_authorized @owner, :show_events?
      refute_authorized @user, :show_events?
      refute_authorized nil, :show_events?
    end
  end

  context "#configure_trusted_publishers?" do
    should "only allow the owner" do
      assert_authorized @owner, :configure_trusted_publishers?
      refute_authorized @user, :configure_trusted_publishers?
      refute_authorized nil, :configure_trusted_publishers?
    end
  end

  context "#show_unconfirmed_ownerships?" do
    should "only allow the owner" do
      assert_authorized @owner, :show_unconfirmed_ownerships?
      refute_authorized @user, :show_unconfirmed_ownerships?
      refute_authorized nil, :show_unconfirmed_ownerships?
    end
  end
end
