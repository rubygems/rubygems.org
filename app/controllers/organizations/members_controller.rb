class Organizations::MembersController < ApplicationController
  before_action :redirect_to_signin, only: :index, unless: :signed_in?
  before_action :redirect_to_new_mfa, only: :index, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, only: :index, if: :mfa_required_weak_level_enabled?

  before_action :find_organization, only: %i[create update destroy]
  before_action :find_membership, only: %i[update destroy]

  layout "subject"

  def index
    @organization = Organization.find_by_handle!(params[:organization_id])
    authorize @organization, :list_memberships?

    @memberships = @organization.memberships.includes(:user)
    @memberships_count = @organization.memberships.count
  end

  def create
    membership = @organization.memberships.new(create_membership_params)
    authorize membership

    if membership.save
      redirect_to organization_members_path(@organization)
    else
      render :index
    end
  end

  def update
    @membership.attributes = update_membership_params
    authorize @membership

    if @membership.save
      redirect_to organization_members_path(@organization)
    else
      redirect_to organization_members_path(@organization), error: "Failed to update membership"
    end
  end

  def destroy
    authorize @membership
    @membership.destroy

    redirect_to organization_members_path(@organization)
  end

  private

  def find_organization
    @organization = Organization.find_by_handle!(params[:organization_id])
    authorize @organization, :manage_memberships?
  end

  def find_membership
    @membership = @organization.memberships.find(params.permit(:id).require(:id))
  end

  def create_membership_params
    params.require(:membership).permit(:user_id, :role)
  end

  def update_membership_params
    params.require(:membership).permit(:role)
  end
end
