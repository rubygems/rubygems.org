require "test_helper"

class Admin::OrganizationOnboardingInvitePolicyTest < AdminPolicyTestCase
  setup do
    @onboarding_invite = FactoryBot.create(:organization_onboarding_invite)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@onboarding_invite], policy_scope!(@admin, OrganizationOnboardingInvite).to_a
  end

  def test_avo_index
    assert_authorizes @admin, OrganizationOnboardingInvite, :avo_index?
    refute_authorizes @non_admin, OrganizationOnboardingInvite, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, OrganizationOnboardingInvite, :avo_show?
    refute_authorizes @non_admin, OrganizationOnboardingInvite, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, OrganizationOnboardingInvite, :avo_create?
    refute_authorizes @non_admin, OrganizationOnboardingInvite, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @onboarding_invite, :avo_update?
    refute_authorizes @non_admin, @onboarding_invite, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @onboarding_invite, :avo_destroy?
    refute_authorizes @non_admin, @onboarding_invite, :avo_destroy?
  end

  def test_act_on
    assert_authorizes @admin, @onboarding_invite, :act_on?
    refute_authorizes @non_admin, @onboarding_invite, :act_on?
  end
end
