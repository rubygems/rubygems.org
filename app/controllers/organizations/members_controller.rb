class Organizations::MembersController < Organizations::BaseController
  before_action :find_membership, only: %i[edit update destroy resend_invitation]

  skip_before_action :redirect_to_signin, only: %i[index]

  rescue_from Pundit::NotAuthorizedError, with: :render_not_found

  def index
    if OrganizationPolicy.new(current_user, @organization).list_memberships?
      @memberships = @organization.memberships_including_unconfirmed.includes(:user)
      @memberships_count = @organization.memberships_including_unconfirmed.count
    else
      @memberships = @organization.memberships.includes(:user)
      @memberships_count = @organization.memberships.count
    end
  end

  def new
    authorize @organization, :invite_member?

    @membership = @organization.memberships.build
    authorize @membership, :create?
  end

  def edit
    authorize @membership, :edit?
  end

  def create
    authorize @organization, :invite_member?

    @membership = @organization.memberships.build(membership_params[:membership].except(:user))
    @membership.user = User.find_by(handle: membership_params[:membership][:user])
    @membership.invited_by = current_user

    if @membership.save
      OrganizationMailer.user_invited(@membership).deliver_later
      redirect_to organization_memberships_path(@organization), notice: t(".member_invited")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @membership, :update?
    if @membership.update(membership_params[:membership])
      redirect_to organization_memberships_path(@organization), notice: t(".member_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @membership, :destroy?
    return redirect_to organization_memberships_path(@organization), alert: t(".cannot_remove_self") if current_user == @membership.user
    @membership.destroy!

    redirect_to organization_memberships_path(@organization), notice: t(".member_removed")
  end

  def resend_invitation
    return redirect_to organization_memberships_path(@organization), alert: t(".already_confirmed") if @membership.confirmed?

    authorize @organization, :invite_member?

    @membership.refresh_invitation!
    OrganizationMailer.user_invited(@membership).deliver_later
    redirect_to organization_memberships_path(@organization), notice: t(".invitation_resent")
  end

  private

  def find_membership
    @membership = @organization.memberships_including_unconfirmed.find(params[:id])
  end

  def membership_params
    params.permit(membership: %i[user role])
  end
end
