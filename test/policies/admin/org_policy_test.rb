require "test_helper"

class Admin::OrgPolicyTest < AdminPolicyTestCase
  setup do
    @org = FactoryBot.create(:org)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@org], policy_scope!(@admin, Org).to_a
  end

  def test_show
    assert_authorizes @admin, @org, :avo_show?
    refute_authorizes @non_admin, @org, :avo_show?
  end

  def test_create
    refute_authorizes @admin, @org, :avo_create?
    refute_authorizes @non_admin, @org, :avo_create?
  end

  def test_update
    refute_authorizes @admin, @org, :avo_update?
    refute_authorizes @non_admin, @org, :avo_update?
  end

  def test_destroy
    refute_authorizes @admin, @org, :avo_destroy?
    refute_authorizes @non_admin, @org, :avo_destroy?
  end

  def test_search
    assert_authorizes @admin, @org, :avo_search?
    refute_authorizes @non_admin, @org, :avo_search?
  end
end
