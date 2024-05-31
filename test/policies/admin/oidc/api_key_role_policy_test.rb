require "test_helper"

class Admin::OIDC::ApiKeyRolePolicyTest < AdminPolicyTestCase
  setup do
    @api_key_role = FactoryBot.create(:oidc_api_key_role)

    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@api_key_role], policy_scope!(
      @admin,
      OIDC::ApiKeyRole
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, OIDC::ApiKeyRole, :avo_index?

    refute_authorizes @non_admin, OIDC::ApiKeyRole, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @api_key_role, :avo_show?

    refute_authorizes @non_admin, @api_key_role, :avo_show?
  end

  def test_avo_create
    assert_authorizes @admin, OIDC::ApiKeyRole, :avo_create?

    refute_authorizes @non_admin, OIDC::ApiKeyRole, :avo_create?
  end

  def test_avo_update
    assert_authorizes @admin, @api_key_role, :avo_update?

    refute_authorizes @non_admin, @api_key_role, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @api_key_role, :avo_destroy?
    refute_authorizes @non_admin, @api_key_role, :avo_destroy?
  end
end
