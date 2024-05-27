require "test_helper"

class Admin::WebHookPolicyTest < AdminPolicyTestCase
  setup do
    @web_hook = FactoryBot.create(:web_hook)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@web_hook], policy_scope!(
      @admin,
      WebHook
    ).to_a
  end

  def test_avo_index
    refute_predicate policy!(@admin, ApiKey), :avo_index?
    refute_predicate policy!(@non_admin, ApiKey), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @web_hook), :avo_show?
    refute_predicate policy!(@non_admin, @web_hook), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, ApiKey), :avo_create?
    refute_predicate policy!(@non_admin, ApiKey), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @web_hook), :avo_update?
    refute_predicate policy!(@non_admin, @web_hook), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @web_hook), :avo_destroy?
    refute_predicate policy!(@non_admin, @web_hook), :avo_destroy?
  end

  def test_act_on
    assert_predicate policy!(@admin, @web_hook), :act_on?
    refute_predicate policy!(@non_admin, @web_hook), :act_on?
  end
end
