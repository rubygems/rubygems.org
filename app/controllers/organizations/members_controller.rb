class Organizations::MembersController < Organizations::BaseController
  before_action :find_membership, only: %i[edit update destroy]

  def index
    @memberships = @organization.memberships_including_unconfirmed.includes(:user)
    @memberships_count = @organization.memberships_including_unconfirmed.count
  end

  def new
    @membership = @organization.memberships.build
    authorize @membership, :create?
  end

  def edit
    authorize @membership, :edit?
  end

  def create
    @membership = @organization.memberships.build(membership_params)
    @membership.user = User.find_by(handle: params[:handle])

    authorize @membership, :create?

    if @membership.save
      OrganizationMailer.user_invited(@membership).deliver_later
      redirect_to organization_memberships_path(@organization), notice: t(".member_invited")
    else
      render :new
    end
  end

  def update
    authorize @membership, :destroy?
    if @membership.update(membership_params)
      redirect_to organization_memberships_path(@organization), notice: t(".member_updated")
    else
      render :edit
    end
  end

  def destroy
    authorize @membership, :destroy?
    return redirect_to organization_memberships_path(@organization), alert: t(".cannot_remove_self") if current_user == @membership.user
    @membership.destroy!

    redirect_to organization_memberships_path(@organization), notice: t(".member_removed")
  end

  private

  def find_membership
    @membership = @organization.memberships_including_unconfirmed.find(params[:id])
  end

  def membership_params
    params.permit(:role)
  end
end
