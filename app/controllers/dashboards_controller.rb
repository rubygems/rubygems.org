class DashboardsController < ApplicationController
  before_action :authenticate_with_api_key, unless: :signed_in?
  before_action :redirect_to_signin, unless: -> { signed_in? || @api_user }

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
    api_key = request.headers["Authorization"] || params.permit(:api_key).fetch(:api_key, "")
    return head(:not_acceptable) if api_key.size > 32

    @api_user = User.find_by_api_key(api_key)
  end

  def api_or_logged_in_user
    @api_user || current_user
  end
end
