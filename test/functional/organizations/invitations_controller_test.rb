require "test_helper"

class Organizations::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = create(:organization)
    @membership = create(:membership, :pending, organization: @organization, user: @user)
  end

  test "GET /organizations/:organization_handle/invitation" do
    get organization_invitation_path(@organization, as: @user)

    assert_response :success
  end

  test "PATCH /organizations/:organization_handle/invitation" do
    patch organization_invitation_path(@organization, as: @user)

    assert_redirected_to organization_path(@organization)

    @membership.reload

    assert_not_nil @membership.invitation_expires_at
    assert_predicate @membership, :confirmed?
  end
end
