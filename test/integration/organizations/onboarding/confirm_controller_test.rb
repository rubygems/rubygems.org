require "test_helper"

class Organizations::Onboarding::ConfirmControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @collaborator = create(:user, :mfa_enabled)
    @rubygem = create(:rubygem, owners: [@user, @collaborator])

    @organization_onboarding = create(
      :organization_onboarding,
      created_by: @user,
      invites: [
        OrganizationOnboardingInvite.new(user: @collaborator, role: "maintainer")
      ],
      rubygems: [@rubygem.id]
    )

    sign_in_as(@user)
  end

  context "GET #show" do
    should "to render the show template" do
      get :edit

      assert_template :edit
    end
  end

  context "PATCH #update" do
    should "onboard the organization and render a success message" do
      patch :update

      assert_equal "Organization succesfully onboarded!", response.body

      assert_predicate @organization_onboarding.reload, :completed?
      assert_predicate @organization_onboarding.organization, :present?
    end
  end
end
