class DashboardsController < ApplicationController
  before_action :authenticate_with_api_key, unless: :signed_in?
  before_action :redirect_to_signin, unless: -> { signed_in? || @api_key&.can_show_dashboard? }
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  def show
    respond_to do |format|
      format.html do
        @my_gems         = current_user.rubygems.with_versions.by_name
        @latest_updates  = Version.subscribed_to_by(current_user).published(Gemcutter::DEFAULT_PAGINATION)
        @subscribed_gems = current_user.subscribed_gems.with_versions
      end
      format.atom do
        @versions = Version.subscribed_to_by(api_or_logged_in_user).published(Gemcutter::DEFAULT_PAGINATION)
        render "versions/feed"
      end
    end
  end

  private

  def authenticate_with_api_key
    params_key = request.headers["Authorization"] || params.permit(:api_key).fetch(:api_key, "")
    hashed_key = Digest::SHA256.hexdigest(params_key)
    @api_key   = ApiKey.find_by_hashed_key(hashed_key)
  end

  def api_or_logged_in_user
    current_user || @api_key.user
  end
end
