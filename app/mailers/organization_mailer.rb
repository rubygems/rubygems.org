class OrganizationMailer < ApplicationMailer
  def user_invited(membership)
    @membership = membership
    @user = membership.user
    @organization = membership.organization
    @accept_url = organization_invitation_url(@organization)

    mail(to: @user.email, subject: "You've been invited to join #{@organization.handle}")
  end
end