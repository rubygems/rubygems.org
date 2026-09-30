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

  test "GET /organizations/:organization_handle/invitation shows when the invitation expires" do
    freeze_time do
      @membership.update!(invitation_expires_at: 3.days.from_now)

      get organization_invitation_path(@organization, as: @user)

      assert_response :success
      assert_select "time[datetime=?][title=?]", 3.days.from_now.utc.iso8601, "#{3.days.from_now.utc.strftime('%B %d, %Y %H:%M')} UTC", text: "3 days"
      assert_select ".invitation-container", text: /This invitation expires in 3 days\./
    end
  end

  test "DELETE /organizations/:organization_handle/invitation declines the pending invitation" do
    other_invitee_membership = create(:membership, :pending, organization: @organization)
    other_organization_membership = create(:membership, :pending, user: @user)

    delete organization_invitation_path(@organization, as: @user)

    assert_redirected_to dashboard_path
    assert_equal I18n.t("organizations.invitations.destroy.declined", organization: @organization.handle), flash[:notice]
    refute Membership.exists?(@membership.id)
    assert Membership.exists?(other_invitee_membership.id)
    assert Membership.exists?(other_organization_membership.id)
  end

  test "DELETE /organizations/:organization_handle/invitation declines an expired invitation" do
    @membership.update!(invitation_expires_at: 1.day.ago)

    delete organization_invitation_path(@organization, as: @user)

    assert_redirected_to dashboard_path
    refute Membership.exists?(@membership.id)
  end

  test "DELETE /organizations/:organization_handle/invitation declines an invitation with no expiry" do
    @membership.update!(invitation_expires_at: nil)

    delete organization_invitation_path(@organization, as: @user)

    assert_redirected_to dashboard_path
    refute Membership.exists?(@membership.id)
  end

  test "DELETE /organizations/:organization_handle/invitation with already confirmed membership" do
    @membership.update!(confirmed_at: Time.current)

    delete organization_invitation_path(@organization, as: @user)

    assert_response :not_found
    assert_predicate @membership.reload, :confirmed?
  end

  test "DELETE /organizations/:organization_handle/invitation without an invitation" do
    other_user = create(:user)

    delete organization_invitation_path(@organization, as: other_user)

    assert_response :not_found
    assert Membership.exists?(@membership.id)
  end

  test "DELETE /organizations/:organization_handle/invitation when signed out" do
    delete organization_invitation_path(@organization)

    assert_redirected_to sign_in_path
    assert Membership.exists?(@membership.id)
  end

  test "PATCH /organizations/:organization_handle/invitation when confirmation is refused" do
    Membership.any_instance.stubs(:confirm!).returns(false)

    patch organization_invitation_path(@organization, as: @user)

    assert_redirected_to organization_path(@organization)
    assert_equal I18n.t("organizations.invitations.expired"), flash[:alert]
    refute_predicate @membership.reload, :confirmed?
  end
end
