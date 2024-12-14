class Organizations::GemsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  before_action :find_organization, only: %i[index]

  layout "subject"

  # GET /organizations/organization_id/gems

  def index
    @gems = @organization.rubygems.with_versions.by_downloads.preload(:most_recent_version, :gem_download).load_async
    @gems_count = @organization.rubygems.with_versions.count
  end

  private

  def find_organization
    @organization = Organization.find_by_handle!(params[:organization_id])
  end
end
