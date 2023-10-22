require "test_helper"

class LinkVerificationPolicyTest < ActiveSupport::TestCase
  setup do
    @verification = create(:link_verification)

    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    home_verification = @verification.linkable.link_verifications.for_uri(@verification.linkable.linkset.home).sole

    assert_equal [home_verification, @verification], Pundit.policy_scope!(
      @admin,
      LinkVerification
    ).to_a
  end

  def test_avo_index
    assert_predicate Pundit.policy!(@admin, LinkVerification), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, LinkVerification), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @verification), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @verification), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, LinkVerification), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, LinkVerification), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @verification), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @verification), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @verification), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @verification), :avo_destroy?
  end
end
