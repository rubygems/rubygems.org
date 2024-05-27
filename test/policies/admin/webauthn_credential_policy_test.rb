require "test_helper"

class Admin::WebauthnCredentialPolicyTest < AdminPolicyTestCase
  setup do
    @webauthn_credential = FactoryBot.create(:webauthn_credential)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@webauthn_credential], policy_scope!(
      @admin,
      WebauthnCredential
    ).to_a
  end

  def test_avo_index
    refute_predicate policy!(@admin, WebauthnCredential), :avo_index?
    refute_predicate policy!(@non_admin, WebauthnCredential), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @webauthn_credential), :avo_show?
    refute_predicate policy!(@non_admin, @webauthn_credential), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, WebauthnCredential), :avo_create?
    refute_predicate policy!(@non_admin, WebauthnCredential), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @webauthn_credential), :avo_update?
    refute_predicate policy!(@non_admin, @webauthn_credential), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @webauthn_credential), :avo_destroy?
    refute_predicate policy!(@non_admin, @webauthn_credential), :avo_destroy?
  end
end
