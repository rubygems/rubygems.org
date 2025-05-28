class Organizations::InvitationsController < Organizations::BaseController
  before_action :find_membership, :set_breadcrumbs

  layout "hammy"

  def show
  end

  def update
    @membership.confirm!
    redirect_to organization_path(@organization), notice: "You have successfully joined the #{@organization.handle} organization."
  end

  private

  def find_membership
    @membership = Membership.find_by!(organization: @organization, user: current_user)
  end

  def set_breadcrumbs
    add_breadcrumb "Organizations", organizations_path
    add_breadcrumb @organization.handle, organization_path(@organization)
    add_breadcrumb "Invitation", organization_invitation_path(@organization)
  end
end
