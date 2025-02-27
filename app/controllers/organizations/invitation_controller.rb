class Organizations::InvitationController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  before_action :find_organization

  layout "subject"

  def show
    @membership = Membership.find_by!(organization: @organization)
  end

  def update
    @membership = Membership.find_by!(organization: @organization)
    @membership.confirm!

    redirect_to organization_path(@organization), notice: "You have successfully joined the organization."
  end

  private

  def find_organization
    @organization = Organization.find_by(handle: params[:organization_id])
  end
end