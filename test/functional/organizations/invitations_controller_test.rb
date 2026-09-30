# frozen_string_literal: true

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

  test "GET /organizations/:organization_handle/invitation with already confirmed membership" do
    @membership.update!(confirmed_at: Time.current)

    get organization_invitation_path(@organization, as: @user)

    assert_response :not_found
  end

  test "PATCH /organizations/:organization_handle/invitation" do
    patch organization_invitation_path(@organization, as: @user)

    assert_redirected_to organization_path(@organization)

    @membership.reload

    refute_nil @membership.invitation_expires_at
    assert_predicate @membership, :confirmed?
  end

  test "GET /organizations/:organization_handle/invitation with expired invitation" do
    @membership.update!(invitation_expires_at: 1.day.ago)

    get organization_invitation_path(@organization, as: @user)

    assert_redirected_to organization_path(@organization)
    assert_equal I18n.t("organizations.invitations.expired"), flash[:alert]
  end

  test "PATCH /organizations/:organization_handle/invitation with expired invitation" do
    @membership.update!(invitation_expires_at: 1.day.ago)

    patch organization_invitation_path(@organization, as: @user)

    assert_redirected_to organization_path(@organization)
    assert_equal I18n.t("organizations.invitations.expired"), flash[:alert]
    refute_predicate @membership.reload, :confirmed?
  end

  test "PATCH /organizations/:organization_handle/invitation with no invitation expiry" do
    @membership.update!(invitation_expires_at: nil)

    patch organization_invitation_path(@organization, as: @user)

    assert_redirected_to organization_path(@organization)
    assert_equal I18n.t("organizations.invitations.expired"), flash[:alert]
    refute_predicate @membership.reload, :confirmed?
  end

  test "PATCH /organizations/:organization_handle/invitation when confirmation is refused" do
    Membership.any_instance.stubs(:confirm!).returns(false)

    patch organization_invitation_path(@organization, as: @user)

    assert_redirected_to organization_path(@organization)
    assert_equal I18n.t("organizations.invitations.expired"), flash[:alert]
    refute_predicate @membership.reload, :confirmed?
  end
end
