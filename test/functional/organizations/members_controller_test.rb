require "test_helper"

class Organizations::MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @user = create(:user)
    @membership = create(:membership, organization: @organization, user: @user, role: :admin)

    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "GET /organizations/:organization_handle/members" do
    get organization_memberships_path(@organization)

    assert_response :success
    assert_select "h1", text: "Members"
  end

  test "GET /organizations/:organization_handle/members as a non-member" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get organization_memberships_path(@organization)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/members as maintainer" do
    @membership.update(role: "maintainer")
    get organization_memberships_path(@organization)

    assert_response :success
  end

  test "GET /organizations/:organization_handle/members/new" do
    get new_organization_membership_path(@organization)

    assert_response :success
    assert_select "h3", text: "Invite Member"
  end

  test "GET /organizations/:organization_handle/members/:new as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get new_organization_membership_path(@organization)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/members/new as a maintainer" do
    @membership.update(role: "maintainer")
    get new_organization_membership_path(@organization)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/members/:id/edit" do
    get edit_organization_membership_path(@organization, @membership)

    assert_response :success
  end

  test "GET /organizations/:organization_handle/members/:id/edit as a maintainer" do
    @membership.update(role: "maintainer")
    get edit_organization_membership_path(@organization, @membership)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/members/:id/edit as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get edit_organization_membership_path(@organization, @membership)

    assert_response :not_found
  end

  test "POST /organizations/:organization_handle/members" do
    new_user = create(:user)

    post organization_memberships_path(@organization), params: { membership: { user: new_user.handle, role: :admin } }

    assert_redirected_to organization_memberships_path(@organization)
    assert_equal "Member invited.", flash[:notice]
  end

  test "POST /organizations/:organization_handle/members with invalid values" do
    post organization_memberships_path(@organization), params: { membership: { user: "invalid role", role: :invalid_role } }

    assert_response :unprocessable_entity
  end

  test "POST /organizations/:organization_handle/members as a maintainer" do
    @membership.update(role: "maintainer")
    new_user = create(:user)

    post organization_memberships_path(@organization), params: { membership: { user: new_user.handle, role: :admin } }

    assert_response :not_found
  end

  test "POST /organizations/:organization_handle/members as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    new_user = create(:user)

    post organization_memberships_path(@organization), params: { membership: { user: new_user.handle, role: :admin } }

    assert_response :not_found
  end

  test "PATCH /organizations/:organization_handle/members/:id" do
    patch organization_membership_path(@organization, @membership), params: { membership: { role: "admin" } }

    assert_redirected_to organization_memberships_path(@organization)
    assert_equal "Member updated successfully.", flash[:notice]
  end

  test "PATCH /organizations/:organization_handle/members/:id with invalid values" do
    patch organization_membership_path(@organization, @membership), params: { membership: { role: "invalid_role" } }

    assert_response :unprocessable_entity
  end

  test "PATCH /organizations/:organization_handle/members/:id as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    patch organization_membership_path(@organization, @membership), params: { membership: { role: "admin" } }

    assert_response :not_found
  end

  test "PATCH /organizations/:organization_handle/members/:id as a maintainer" do
    @membership.update(role: "maintainer")
    patch organization_membership_path(@organization, @membership), params: { membership: { role: "admin" } }

    assert_response :not_found
  end

  test "DELETE /organizations/:organization_handle/members/:id" do
    new_user = create(:user)
    membership = create(:membership, organization: @organization, user: new_user)

    delete organization_membership_path(@organization, membership)

    assert_redirected_to organization_memberships_path(@organization)
    assert_equal "Member removed successfully.", flash[:notice]
  end

  test "DELETE /organizations/:organization_handle/members/:id as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    delete organization_membership_path(@organization, @membership)

    assert_response :not_found
  end

  test "DELETE /organizations/:organization_handle/members/:id as a maintainer" do
    @membership.update(role: "maintainer")
    delete organization_membership_path(@organization, @membership)

    assert_response :not_found
  end

  test "DELETE /organizations/:organization_handle/members/:id with current user's membership" do
    delete organization_membership_path(@organization, @membership)

    assert_redirected_to organization_memberships_path(@organization)
    assert_equal "You cannot remove yourself from the organization.", flash[:alert]
  end
end
