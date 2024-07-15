require "test_helper"

class Admin::OrganizationPolicyTest < AdminPolicyTestCase
  setup do
    @organization = FactoryBot.create(:organization)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@organization], policy_scope!(@admin, Organization).to_a
  end

  def test_show
    assert_authorizes @admin, @organization, :avo_show?
    refute_authorizes @non_admin, @organization, :avo_show?
  end

  def test_create
    refute_authorizes @admin, @organization, :avo_create?
    refute_authorizes @non_admin, @organization, :avo_create?
  end

  def test_update
    refute_authorizes @admin, @organization, :avo_update?
    refute_authorizes @non_admin, @organization, :avo_update?
  end

  def test_destroy
    refute_authorizes @admin, @organization, :avo_destroy?
    refute_authorizes @non_admin, @organization, :avo_destroy?
  end

  def test_search
    assert_authorizes @admin, @organization, :avo_search?
    refute_authorizes @non_admin, @organization, :avo_search?
  end
end
