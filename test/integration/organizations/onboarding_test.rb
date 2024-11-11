require "test_helper"

class Organizations::OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  context "GET /organizations/onboarding" do
    should "redirect to onboarding start page" do
      get "/organizations/onboarding"

      assert_redirected_to organization_onboarding_name_path
    end
  end

  context "DELETE /organizations/onboarding" do
    should "not destroy an OrganizationOnboarding that is already completed" do
      organization_onboarding = create(:organization_onboarding, :completed, created_by: @user)

      delete "/organizations/onboarding"

      assert_redirected_to dashboard_path
      assert OrganizationOnboarding.find_by(id: organization_onboarding.id)
    end

    should "destroy an existing OrganizationOnboarding created by the current user" do
      organization_onboarding = create(:organization_onboarding, created_by: @user)

      delete "/organizations/onboarding"

      assert_redirected_to dashboard_path
      assert_nil OrganizationOnboarding.find_by(id: organization_onboarding.id)
    end

    should "redirect to the dashboarding if the current user has not started organization onboarding" do
      delete "/organizations/onboarding"

      assert_redirected_to dashboard_path
    end
  end
end
