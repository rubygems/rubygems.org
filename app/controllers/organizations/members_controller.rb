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
    username, role = create_membership_params.require([:username, :role])
    # we can open this up in the future to handle email too via find_by_name,
    # but it will need to use an invite process to handle non-existing users.
    member = User.find_by(handle: username)
    if member
      membership = authorize @organization.memberships.build(user: member, role:)
      if membership.save
        flash[:notice] = t(".success", username: member.name)
      else
        flash[:error] = t(".failure", error: membership.errors.full_messages.to_sentence)
      end
    else
      flash[:error] = t(".failure", error: t(".user_not_found"))
    end
    redirect_to organization_members_path(@organization)
  end

  def update
    @membership.attributes = update_membership_params
    authorize @membership
    if @membership.save
      flash[:notice] = t(".success")
    else
      flash[:error] = t(".failure", error: membership.errors.full_messages.to_sentence)
    end
    redirect_to organization_members_path(@organization)
  end

  def destroy
    authorize @membership
    flash[:notice] = t(".success") if @membership.destroy
    redirect_to organization_members_path(@organization)
  end

  private

  def find_organization
    @organization = Organization.find_by_handle!(params[:organization_id])
    authorize @organization, :manage_memberships?
  end

  def find_membership
    handle = params.permit(:id).require(:id)
    @member = User.find_by_slug!(handle)
    @membership = @organization.memberships.find_by!(user: @member)
  end

  def create_membership_params
    params.permit(membership: %i[username role]).require(:membership)
  end

  def update_membership_params
    params.permit(membership: %i[role]).require(:membership)
  end
end
