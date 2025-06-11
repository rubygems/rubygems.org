class Organizations::InvitationsController < Organizations::BaseController
  before_action :find_membership

  layout "hammy"

  def show
  end

  def update
    @membership.confirm!
    redirect_to organization_path(@organization), notice: "You have successfully joined the #{@organization.handle} organization."
  end

  private

  def find_membership
    @membership = Membership.find_by!(organization: @organization, user: current_user, confirmed_at: nil)
  end
end
