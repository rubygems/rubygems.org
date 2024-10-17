require "test_helper"

class Onboarding::ConfirmControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending)

    sign_in_as(@user)
  end

  context "PATCH #update" do
    should "onboard the organization and render a success message" do
      patch :update

      assert_equal "Organization succesfully onboarded!", response.body
    end
  end
end
