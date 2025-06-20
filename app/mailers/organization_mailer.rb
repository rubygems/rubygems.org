class OrganizationMailer < ApplicationMailer
  def user_invited(membership)
    @membership = membership
    @user = membership.user
    @invited_by = membership.invited_by
    @organization = membership.organization
    @accept_url = organization_invitation_url(@organization, host: Gemcutter::HOST)

    mail(to: @user.email, subject: "You've been invited to join #{@organization.handle}")
  end
end
