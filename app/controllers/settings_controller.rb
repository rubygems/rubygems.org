class SettingsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :set_cache_headers

  def edit
    @user = current_user
  end

  private

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
