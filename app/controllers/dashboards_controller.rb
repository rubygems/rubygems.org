class DashboardsController < ApplicationController
  before_action :authenticate_with_api_key, unless: :signed_in?
  before_action :redirect_to_root, unless: :signed_in?

  DEFAULT_PAGINATION = 20

  def show
    respond_to do |format|
      format.html do
        @my_gems         = current_user.rubygems.with_versions.by_name
        @latest_updates  = Version.subscribed_to_by(current_user).published(DEFAULT_PAGINATION)
        @subscribed_gems = current_user.subscribed_gems.with_versions
      end
      format.atom do
        @versions = Version.subscribed_to_by(current_user).published(DEFAULT_PAGINATION)
        render 'versions/feed'
      end
    end
  end
end
