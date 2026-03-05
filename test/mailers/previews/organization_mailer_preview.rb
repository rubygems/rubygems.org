# frozen_string_literal: true

class OrganizationMailerPreview < ActionMailer::Preview
  def organization_invitation
    OrganizationMailer.user_invited(Membership.last)
  end
end
