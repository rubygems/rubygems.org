require "test_helper"

class Onboarding::GemsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @gem = create(:rubygem, owners: [@user])
    @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending, organization_name: "Existing Name")

    sign_in_as(@user)
  end

  context "PATCH update" do
    should "save the selected gems and redirect to the next step" do
      patch :update, params: { organization_onboarding: { rubygems: [@gem.id] } }

      assert_redirected_to onboarding_users_path
      assert_equal [@gem.id], @organization_onboarding.reload.rubygems
    end
  end
end
