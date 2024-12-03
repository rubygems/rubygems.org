require "test_helper"

class Admin::ApiKeyPolicyTest < AdminPolicyTestCase
  setup do
    @api_key = FactoryBot.create(:api_key)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@api_key], policy_scope!(
      @admin,
      ApiKey
    ).to_a
  end

  def test_associations
    assert_association @admin, @api_key, :api_key_rubygem_scope, Admin::ApiKeyPolicy
    assert_association @admin, @api_key, :ownership, Admin::OwnershipPolicy
    assert_association @admin, @api_key, :oidc_id_token, Admin::OIDC::IdTokenPolicy
  end

  def test_avo_index
    refute_authorizes @admin, ApiKey, :avo_index?
    refute_authorizes @non_admin, ApiKey, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @api_key, :avo_show?
    refute_authorizes @non_admin, @api_key, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, ApiKey, :avo_create?
    refute_authorizes @non_admin, ApiKey, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @api_key, :avo_update?
    refute_authorizes @non_admin, @api_key, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @api_key, :avo_destroy?
    refute_authorizes @non_admin, @api_key, :avo_destroy?
  end
end
