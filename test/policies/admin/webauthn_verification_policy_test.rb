require "test_helper"

class Admin::WebauthnVerificationPolicyTest < AdminPolicyTestCase
  setup do
    @webauthn_verification = FactoryBot.create(:webauthn_verification)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@webauthn_verification], policy_scope!(
      @admin,
      WebauthnVerification
    ).to_a
  end

  def test_avo_index
    refute_predicate policy!(@admin, WebauthnVerification), :avo_index?
    refute_predicate policy!(@non_admin, WebauthnVerification), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @webauthn_verification), :avo_show?
    refute_predicate policy!(@non_admin, @webauthn_verification), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, WebauthnVerification), :avo_create?
    refute_predicate policy!(@non_admin, WebauthnVerification), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @webauthn_verification), :avo_update?
    refute_predicate policy!(@non_admin, @webauthn_verification), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @webauthn_verification), :avo_destroy?
    refute_predicate policy!(@non_admin, @webauthn_verification), :avo_destroy?
  end
end
