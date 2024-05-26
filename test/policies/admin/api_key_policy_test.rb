require "test_helper"

class Admin::ApiKeyPolicyTest < ActiveSupport::TestCase
  setup do
    @api_key = FactoryBot.create(:api_key)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@api_key], Pundit.policy_scope!(
      @admin,
      ApiKey
    ).to_a
  end

  def test_avo_index
    refute_predicate Pundit.policy!(@admin, ApiKey), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, ApiKey), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @api_key), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @api_key), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, ApiKey), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, ApiKey), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @api_key), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @api_key), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @api_key), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @api_key), :avo_destroy?
  end
end
