require "test_helper"

class OIDC::PendingTrustedPublisherPolicyTest < ActiveSupport::TestCase
  setup do
    @pending_trusted_publisher = create(:oidc_pending_trusted_publisher)

    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@pending_trusted_publisher], Pundit.policy_scope!(
      @admin,
      OIDC::PendingTrustedPublisher
    ).to_a
  end

  def test_avo_index
    assert_predicate Pundit.policy!(@admin, OIDC::PendingTrustedPublisher), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, OIDC::PendingTrustedPublisher), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @pending_trusted_publisher), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @pending_trusted_publisher), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, OIDC::PendingTrustedPublisher), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, OIDC::PendingTrustedPublisher), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @pending_trusted_publisher), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @pending_trusted_publisher), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @pending_trusted_publisher), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @pending_trusted_publisher), :avo_destroy?
  end
end
