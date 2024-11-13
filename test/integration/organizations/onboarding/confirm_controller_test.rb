require "test_helper"

class Organizations::Onboarding::ConfirmControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    @collaborator = create(:user, :mfa_enabled)
    @rubygem = create(:rubygem, owners: [@user, @collaborator])

    @organization_onboarding = create(
      :organization_onboarding,
      :gem,
      created_by: @user,
      namesake_rubygem: @rubygem,
      approved_invites: [{ user: @collaborator, role: "maintainer" }]
    )
  end

  context "GET #show" do
    should "to render the show template" do
      get "/organizations/onboarding/confirm"

      assert_response :ok
    end
  end

  context "PATCH #update" do
    should "onboard the organization and render a success message" do
      patch "/organizations/onboarding/confirm"

      assert_redirected_to organization_path(@organization_onboarding.reload.organization)

      follow_redirect!

      assert page.has_content?("Organization onboarded successfully")

      assert_predicate @organization_onboarding.reload, :completed?
      assert_predicate @organization_onboarding.organization, :present?

      organization = @organization_onboarding.organization

      assert_equal organization, @organization_onboarding.organization
      assert_equal organization, @user.organizations.first
      assert_equal organization, @collaborator.organizations.first

      assert_predicate @user.memberships.find_by(organization:), :owner?
      assert_predicate @collaborator.memberships.find_by(organization:), :maintainer?

      assert_equal @rubygem.reload.organization, organization
    end

    should "fail to onboard the organization and render an error message" do
      @conflicting_org = create(:organization, handle: @organization_onboarding.organization_handle)

      patch "/organizations/onboarding/confirm"

      assert page.has_content?("Onboarding error: Validation failed: Handle has already been taken")

      assert_predicate @organization_onboarding.reload, :failed?
      assert_nil @organization_onboarding.organization
    end
  end
end
