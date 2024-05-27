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

  def test_avo_index
    refute_predicate policy!(@admin, ApiKey), :avo_index?
    refute_predicate policy!(@non_admin, ApiKey), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @api_key), :avo_show?
    refute_predicate policy!(@non_admin, @api_key), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, ApiKey), :avo_create?
    refute_predicate policy!(@non_admin, ApiKey), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @api_key), :avo_update?
    refute_predicate policy!(@non_admin, @api_key), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @api_key), :avo_destroy?
    refute_predicate policy!(@non_admin, @api_key), :avo_destroy?
  end
end
