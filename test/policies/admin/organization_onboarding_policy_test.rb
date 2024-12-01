require "test_helper"

class Admin::OrganizationOnboardingPolicyTest < AdminPolicyTestCase
  setup do
    @onboarding = FactoryBot.create(:organization_onboarding)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@onboarding], policy_scope!(@admin, OrganizationOnboarding).to_a
  end

  def test_avo_index
    assert_authorizes @admin, OrganizationOnboarding, :avo_index?
    refute_authorizes @non_admin, OrganizationOnboarding, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, OrganizationOnboarding, :avo_show?
    refute_authorizes @non_admin, OrganizationOnboarding, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, OrganizationOnboarding, :avo_create?
    refute_authorizes @non_admin, OrganizationOnboarding, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @onboarding, :avo_update?
    refute_authorizes @non_admin, @onboarding, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @onboarding, :avo_destroy?
    refute_authorizes @non_admin, @onboarding, :avo_destroy?
  end

  def test_act_on
    assert_authorizes @admin, @onboarding, :act_on?
    refute_authorizes @non_admin, @onboarding, :act_on?
  end
end
