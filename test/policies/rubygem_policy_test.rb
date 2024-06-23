require "test_helper"

class RubygemPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])
    @user = create(:user)
  end

  def test_scope
    # Tests that nothing is returned currently because scope is unused
    assert_empty Pundit.policy_scope!(@owner, Rubygem).to_a
    assert_empty Pundit.policy_scope!(@user, Rubygem).to_a
  end

  def test_show
    assert_predicate Pundit.policy!(@owner, @rubygem), :show?
    assert_predicate Pundit.policy!(nil, @rubygem), :show?
  end

  context "#request_ownership?" do
    should "be false if the gem is owned by the user" do
      refute_predicate Pundit.policy!(@owner, @rubygem), :request_ownership?
    end

    should "be true if the gem has ownership calls" do
      create(:ownership_call, rubygem: @rubygem, user: @owner)

      assert_predicate Pundit.policy!(@user, @rubygem), :request_ownership?
    end

    should "be false if the gem has more than 10,000 downloads" do
      @rubygem = create(:rubygem, owners: [@owner], downloads: 10_001)
      create(:version, rubygem: @rubygem, created_at: 2.years.ago)

      assert_operator @rubygem.downloads, :>, RubygemPolicy::ABANDONED_DOWNLOADS_MAX
      refute_predicate Pundit.policy!(@user, @rubygem), :request_ownership?
    end

    should "be false if the gem has no versions" do
      assert_empty @rubygem.versions
      refute_predicate Pundit.policy!(@user, @rubygem), :request_ownership?
    end

    should "be false if the gem has a version newer than 1 year" do
      create(:version, rubygem: @rubygem, created_at: 11.months.ago)

      refute_predicate Pundit.policy!(@user, @rubygem), :request_ownership?
    end

    should "be true if the gem's latest version is older than 1 year and less than 10,000 downloads" do
      create(:version, rubygem: @rubygem, created_at: 2.years.ago)

      assert_predicate Pundit.policy!(@user, @rubygem), :request_ownership?
    end
  end

  context "#show_adoption?" do
    should "be true if the gem is owned by the user" do
      assert_predicate Pundit.policy!(@owner, @rubygem), :show_adoption?
    end

    should "be true if the rubygem is adoptable" do
      create(:version, rubygem: @rubygem, created_at: 2.years.ago)

      assert_predicate Pundit.policy!(@owner, @rubygem), :show_adoption?
    end
  end

  context "#show_events?" do
    should "only allow the owner" do
      assert_predicate Pundit.policy!(@owner, @rubygem), :show_events?
      refute_predicate Pundit.policy!(@user, @rubygem), :show_events?
      refute_predicate Pundit.policy!(nil, @rubygem), :show_events?
    end
  end

  context "#show_trusted_publishers?" do
    should "only allow the owner" do
      assert_predicate Pundit.policy!(@owner, @rubygem), :show_trusted_publishers?
      refute_predicate Pundit.policy!(@user, @rubygem), :show_trusted_publishers?
      refute_predicate Pundit.policy!(nil, @rubygem), :show_trusted_publishers?
    end
  end

  context "#show_unconfirmed_ownerships?" do
    should "only allow the owner" do
      assert_predicate Pundit.policy!(@owner, @rubygem), :show_unconfirmed_ownerships?
      refute_predicate Pundit.policy!(@user, @rubygem), :show_unconfirmed_ownerships?
      refute_predicate Pundit.policy!(nil, @rubygem), :show_unconfirmed_ownerships?
    end
  end
end
