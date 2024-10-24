require "test_helper"

class Onboarding::UsersControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @other_user = create(:user)
    @gem = create(:rubygem, owners: [@user, @other_user])

    sign_in_as(@user)

    @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending)
  end

  test "render the list of users to invite" do
    get :edit

    assert_response :ok
    assert_select "input[type=checkbox][name='organization_onboarding[invitees][][id]']"
  end

  test "should update user" do
    patch :update, params: { organization_onboarding: { invitees: [{ id: @user.id, role: "owner" }] } }

    assert_redirected_to onboarding_confirm_path
  end
end
