require "test_helper"

class Admin::OIDC::TrustedPublisher::GitHubActionPolicyTest < ActiveSupport::TestCase
  setup do
    @trusted_publisher_github_action = create(:oidc_trusted_publisher_github_action)

    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@trusted_publisher_github_action], Pundit.policy_scope!(
      @admin,
      OIDC::TrustedPublisher::GitHubAction
    ).to_a
  end

  def test_avo_index
    assert_predicate Pundit.policy!(@admin, OIDC::TrustedPublisher::GitHubAction), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, OIDC::TrustedPublisher::GitHubAction), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @trusted_publisher_github_action), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @trusted_publisher_github_action), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, OIDC::TrustedPublisher::GitHubAction), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, OIDC::TrustedPublisher::GitHubAction), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @trusted_publisher_github_action), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @trusted_publisher_github_action), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @trusted_publisher_github_action), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @trusted_publisher_github_action), :avo_destroy?
  end
end
