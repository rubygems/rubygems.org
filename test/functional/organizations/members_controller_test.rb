# frozen_string_literal: true

require "test_helper"

class Organizations::MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @user = create(:user)
    @membership = create(:membership, organization: @organization, user: @user, role: :admin)

    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "GET /organizations/:organization_handle/members" do
    get organization_memberships_path(organization_id: @organization)

    assert_response :success
    assert_select "h1", text: "Members"
  end

  test "GET /organizations/:organization_handle/members as a non-member" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get organization_memberships_path(organization_id: @organization)

    assert_response :success
  end

  test "GET /organizations/:organization_handle/members as maintainer" do
    @membership.update(role: "maintainer")
    get organization_memberships_path(organization_id: @organization)

    assert_response :success
  end

  test "GET /organizations/:organization_handle/members/new" do
    get new_organization_membership_path(organization_id: @organization)

    assert_response :success
    assert_select "h3", text: "Invite Member"
  end

  test "GET /organizations/:organization_handle/members/:new as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get new_organization_membership_path(organization_id: @organization)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/members/new as a maintainer" do
    @membership.update(role: "maintainer")
    get new_organization_membership_path(organization_id: @organization)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/members/:id/edit" do
    get edit_organization_membership_path(organization_id: @organization, id: @membership)

    assert_response :success
  end

  test "GET /organizations/:organization_handle/members/:id/edit as a maintainer" do
    @membership.update(role: "maintainer")
    get edit_organization_membership_path(organization_id: @organization, id: @membership)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/members/:id/edit as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get edit_organization_membership_path(organization_id: @organization, id: @membership)

    assert_response :not_found
  end

  test "POST /organizations/:organization_handle/members" do
    new_user = create(:user)

    post organization_memberships_path(organization_id: @organization), params: { membership: { user: new_user.handle, role: :admin } }

    assert_redirected_to organization_memberships_path(organization_id: @organization)
    assert_equal "Member invited.", flash[:notice]
  end

  test "POST /organizations/:organization_handle/members as an admin inviting an owner is forbidden" do
    new_user = create(:user)

    assert_no_difference -> { @organization.memberships.where(role: "owner").count } do
      post organization_memberships_path(@organization), params: { membership: { user: new_user.handle, role: :owner } }
    end

    assert_response :not_found
    assert_nil Membership.find_by(user: new_user, organization: @organization)
  end

  test "POST /organizations/:organization_handle/members with invalid values" do
    post organization_memberships_path(organization_id: @organization), params: { membership: { user: "invalid role", role: :invalid_role } }

    assert_response :unprocessable_content
  end

  test "POST /organizations/:organization_handle/members as a maintainer" do
    @membership.update(role: "maintainer")
    new_user = create(:user)

    post organization_memberships_path(organization_id: @organization), params: { membership: { user: new_user.handle, role: :admin } }

    assert_response :not_found
  end

  test "POST /organizations/:organization_handle/members as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    new_user = create(:user)

    post organization_memberships_path(organization_id: @organization), params: { membership: { user: new_user.handle, role: :admin } }

    assert_response :not_found
  end

  test "PATCH /organizations/:organization_handle/members/:id" do
    patch organization_membership_path(organization_id: @organization, id: @membership), params: { membership: { role: "admin" } }

    assert_redirected_to organization_memberships_path(organization_id: @organization)
    assert_equal "Member updated successfully.", flash[:notice]
  end

  test "PATCH /organizations/:organization_handle/members/:id as an admin promoting a maintainer to owner is forbidden" do
    maintainer_user = create(:user)
    maintainer_membership = create(:membership, organization: @organization, user: maintainer_user, role: :maintainer)

    patch organization_membership_path(@organization, maintainer_membership), params: { membership: { role: "owner" } }

    assert_response :not_found
    assert_equal "maintainer", maintainer_membership.reload.role
  end

  test "PATCH /organizations/:organization_handle/members/:id as an admin demoting an owner is forbidden" do
    owner_user = create(:user)
    owner_membership = create(:membership, organization: @organization, user: owner_user, role: :owner)

    patch organization_membership_path(@organization, owner_membership), params: { membership: { role: "admin" } }

    assert_response :not_found
    assert_equal "owner", owner_membership.reload.role
  end

  test "PATCH /organizations/:organization_handle/members/:id as an owner promoting a maintainer to owner succeeds" do
    owner_user = create(:user)
    create(:membership, organization: @organization, user: owner_user, role: :owner)
    post session_path(session: { who: owner_user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    maintainer_user = create(:user)
    maintainer_membership = create(:membership, organization: @organization, user: maintainer_user, role: :maintainer)

    patch organization_membership_path(@organization, maintainer_membership), params: { membership: { role: "owner" } }

    assert_redirected_to organization_memberships_path(@organization)
    assert_equal "owner", maintainer_membership.reload.role
  end

  test "PATCH /organizations/:organization_handle/members/:id with invalid values" do
    patch organization_membership_path(organization_id: @organization, id: @membership), params: { membership: { role: "invalid_role" } }

    assert_response :unprocessable_content
  end

  test "PATCH /organizations/:organization_handle/members/:id as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    patch organization_membership_path(organization_id: @organization, id: @membership), params: { membership: { role: "admin" } }

    assert_response :not_found
  end

  test "PATCH /organizations/:organization_handle/members/:id as a maintainer" do
    @membership.update(role: "maintainer")
    patch organization_membership_path(organization_id: @organization, id: @membership), params: { membership: { role: "admin" } }

    assert_response :not_found
  end

  test "DELETE /organizations/:organization_handle/members/:id" do
    new_user = create(:user)
    membership = create(:membership, organization: @organization, user: new_user)

    delete organization_membership_path(organization_id: @organization, id: membership)

    assert_redirected_to organization_memberships_path(organization_id: @organization)
    assert_equal "Member removed successfully.", flash[:notice]
  end

  test "DELETE /organizations/:organization_handle/members/:id as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    delete organization_membership_path(organization_id: @organization, id: @membership)

    assert_response :not_found
  end

  test "DELETE /organizations/:organization_handle/members/:id as a maintainer" do
    @membership.update(role: "maintainer")
    delete organization_membership_path(organization_id: @organization, id: @membership)

    assert_response :not_found
  end

  test "DELETE /organizations/:organization_handle/members/:id with current user's membership" do
    delete organization_membership_path(organization_id: @organization, id: @membership)

    assert_redirected_to organization_memberships_path(organization_id: @organization)
    assert_equal "You cannot remove yourself from the organization.", flash[:alert]
  end

  test "PATCH /organizations/:organization_handle/members/:id/resend_invitation with pending membership" do
    pending_user = create(:user)
    pending_membership = create(:membership, :pending, organization: @organization, user: pending_user)

    assert_enqueued_with job: ActionMailer::MailDeliveryJob do
      patch resend_invitation_organization_membership_path(organization_id: @organization, id: pending_membership)
    end

    assert_redirected_to organization_memberships_path(organization_id: @organization)
    assert_equal "Invitation resent successfully.", flash[:notice]
  end

  test "PATCH /organizations/:organization_handle/members/:id/resend_invitation with confirmed membership" do
    patch resend_invitation_organization_membership_path(organization_id: @organization, id: @membership)

    assert_redirected_to organization_memberships_path(organization_id: @organization)
    assert_equal "Member is already confirmed.", flash[:alert]
  end

  test "PATCH /organizations/:organization_handle/members/:id/resend_invitation as a maintainer" do
    @membership.update(role: "maintainer")
    pending_user = create(:user)
    pending_membership = create(:membership, :pending, organization: @organization, user: pending_user)

    patch resend_invitation_organization_membership_path(organization_id: @organization, id: pending_membership)

    assert_response :not_found
  end

  test "PATCH /organizations/:organization_handle/members/:id/resend as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    pending_user = create(:user)
    pending_membership = create(:membership, :pending, organization: @organization, user: pending_user)

    patch resend_invitation_organization_membership_path(organization_id: @organization, id: pending_membership)

    assert_response :not_found
  end
end
