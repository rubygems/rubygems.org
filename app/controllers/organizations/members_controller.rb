class Organizations::MembersController < Organizations::BaseController
  before_action :find_membership, only: %i[show update]

  def index
    @memberships = @organization.memberships_including_unconfirmed.includes(:user)
    @memberships_count = @organization.memberships_including_unconfirmed.count
  end

  def show
  end

  def update
  end

  private

  def find_membership
    @membership = @organization.memberships_including_unconfirmed.find(params[:id])
  end
end
