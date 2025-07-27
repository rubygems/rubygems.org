require "application_system_test_case"

class InvitationTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  setup do
    @user = create(:user)
    @organization = create(:organization, name: "Test Organization")
    @membership = create(:membership, user: @user, organization: @organization, role: :admin)

    @outside_user = create(:user)
  end

  test "inviting a user to an organization" do
    sign_in

    visit organization_path(@organization)
    click_on "Invite"

    fill_in "Handle", with: @outside_user.handle
    select "Maintainer", from: "Role"

    click_on "Invite"

    assert_text I18n.t("organizations.members.create.member_invited")
  end

  test "accepting an invitation to an organization" do
    membership = create(:membership, :pending, user: @outside_user, organization: @organization, invited_by: @user)
    OrganizationMailer.user_invited(membership).deliver_now

    sign_in @outside_user

    invitation = Capybara.string(ActionMailer::Base.deliveries.last.html_part.body.to_s)

    assert invitation.has_text? "#{@user.handle} has invited you to join the #{@organization.handle} organization on rubygems.org."

    invitation_link = invitation.find(:link, "Accept invitation")[:href]
    invitation_path = URI.parse(invitation_link).request_uri

    visit invitation_path

    assert_text "#{@organization.name} invited you to join their organization"

    click_on "Accept"

    assert_text "You have successfully joined the #{@organization.handle} organization."
  end
end
