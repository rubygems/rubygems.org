require "test_helper"

class Admin::ApiKeyRubygemScopePolicyTest < AdminPolicyTestCase
  setup do
    @scope = FactoryBot.create(:api_key_rubygem_scope)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@scope], policy_scope!(
      @admin,
      ApiKeyRubygemScope
    ).to_a
  end

  def test_avo_index
    refute_authorizes @admin, ApiKeyRubygemScope, :avo_index?
    refute_authorizes @non_admin, ApiKeyRubygemScope, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @scope, :avo_show?

    refute_authorizes @non_admin, @scope, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, ApiKeyRubygemScope, :avo_create?
    refute_authorizes @non_admin, ApiKeyRubygemScope, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @scope, :avo_update?
    refute_authorizes @non_admin, @scope, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @scope, :avo_destroy?
    refute_authorizes @non_admin, @scope, :avo_destroy?
  end
end
