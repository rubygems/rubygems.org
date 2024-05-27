require "test_helper"

class Admin::OIDC::ProviderPolicyTest < AdminPolicyTestCase
  setup do
    @provider = FactoryBot.create(:oidc_provider)

    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@provider], policy_scope!(
      @admin,
      OIDC::Provider
    ).to_a
  end

  def test_avo_index
    assert_predicate policy!(@admin, OIDC::Provider), :avo_index?
    refute_predicate policy!(@non_admin, OIDC::Provider), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @provider), :avo_show?
    refute_predicate policy!(@non_admin, @provider), :avo_show?
  end

  def test_avo_create
    assert_predicate policy!(@admin, OIDC::Provider), :avo_create?
    refute_predicate policy!(@non_admin, OIDC::Provider), :avo_create?
  end

  def test_avo_update
    assert_predicate policy!(@admin, @provider), :avo_update?
    refute_predicate policy!(@non_admin, @provider), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @provider), :avo_destroy?
    refute_predicate policy!(@non_admin, @provider), :avo_destroy?
  end
end
