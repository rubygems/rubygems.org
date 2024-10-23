require "test_helper"

class Onboarding::ConfirmControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @collaborator = create(:user, :mfa_enabled)
    @rubygem = create(:rubygem, owners: [@user, @collaborator])

    @organization_onboarding = create(
      :organization_onboarding,
      created_by: @user,
      invitees: [{ id: @collaborator.id, role: :owner }],
      rubygems: [@rubygem.id]
    )

    sign_in_as(@user)
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
