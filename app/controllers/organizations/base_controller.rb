class Organizations::BaseController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  before_action :find_organization

  layout "subject"

  private

  def find_organization
    @organization = Organization.find_by(handle: params[:organization_id])
  end
end
