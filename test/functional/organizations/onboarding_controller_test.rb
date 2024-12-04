require "test_helper"

class Organizations::OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  context "GET /organizations/onboarding" do
    should "redirect to onboarding start page" do
      get organization_onboarding_path(as: @user)

      assert_redirected_to organization_onboarding_name_path
    end
  end

  context "DELETE /organizations/onboarding" do
    context "when onboarding is already completed" do
      should "not destroy the OrganizationOnboarding" do
        organization_onboarding = create(:organization_onboarding, :completed, created_by: @user)

        delete organization_onboarding_path(as: @user)

        assert_redirected_to dashboard_path
        assert OrganizationOnboarding.exists?(id: organization_onboarding.id)
      end
    end

    context "when user has a pending onboarding" do
      should "destroy the OrganizationOnboarding" do
        organization_onboarding = create(:organization_onboarding, created_by: @user)

        delete organization_onboarding_path(as: @user)

        assert_redirected_to dashboard_path
        refute OrganizationOnboarding.exists?(id: organization_onboarding.id)
      end
    end

    context "when user has a failed onboarding" do
      should "destroy the OrganizationOnboarding" do
        organization_onboarding = create(:organization_onboarding, :failed, created_by: @user)

        delete organization_onboarding_path(as: @user)

        assert_redirected_to dashboard_path
        refute OrganizationOnboarding.exists?(id: organization_onboarding.id)
      end
    end

    context "when the current user has not started onboarding" do
      should "redirect to the dashboard" do
        assert_no_difference -> { OrganizationOnboarding.count } do
          delete organization_onboarding_path(as: @user)
        end

        assert_redirected_to dashboard_path
      end
    end
  end
end
