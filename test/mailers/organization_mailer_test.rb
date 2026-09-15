# frozen_string_literal: true

require "test_helper"

class OrganizationMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  test "invite user to join organization" do
    user = create(:user)
    organization = create(:organization)
    membership = create(:membership, organization: organization, user: user)

    email = OrganizationMailer.user_invited(membership)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_equal "You've been invited to join #{organization.handle}", email.subject
  end

  test "invitation email styles the accept link as a button" do
    user = create(:user)
    organization = create(:organization)
    membership = create(:membership, organization: organization, user: user)

    OrganizationMailer.user_invited(membership).deliver_now

    assert_cta_button organization_invitation_url(organization, host: Gemcutter::HOST), "ACCEPT INVITATION"
  end
end
