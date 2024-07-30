require "test_helper"

class OIDC::PendingTrustedPublisherPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @trusted_publisher = create(:oidc_pending_trusted_publisher, rubygem_name: "pending-gem-name", user: @owner)
    @user = create(:user)
  end

  def test_scope
    assert_same_elements(
      [@trusted_publisher],
      Pundit.policy_scope!(@owner, OIDC::PendingTrustedPublisher).to_a
    )
    assert_same_elements(
      [@trusted_publisher],
      Pundit.policy_scope!(@owner, @owner.oidc_pending_trusted_publishers).to_a
    )

    assert_empty Pundit.policy_scope!(@user, OIDC::PendingTrustedPublisher).to_a
    assert_empty Pundit.policy_scope!(@user, @user.oidc_pending_trusted_publishers).to_a
  end

  def test_show
    assert_predicate Pundit.policy!(@owner, @trusted_publisher), :show?
    refute_predicate Pundit.policy!(@user, @trusted_publisher), :show?
    refute_predicate Pundit.policy!(nil, @trusted_publisher), :show?
  end

  def test_create
    assert_predicate Pundit.policy!(@owner, @trusted_publisher), :create?
    refute_predicate Pundit.policy!(@user, @trusted_publisher), :create?
    refute_predicate Pundit.policy!(nil, @trusted_publisher), :create?
  end

  def test_destroy
    assert_predicate Pundit.policy!(@owner, @trusted_publisher), :destroy?
    refute_predicate Pundit.policy!(@user, @trusted_publisher), :destroy?
    refute_predicate Pundit.policy!(nil, @trusted_publisher), :destroy?
  end
end
