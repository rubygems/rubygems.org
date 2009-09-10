class DashboardsController < ApplicationController

  before_filter :authenticate_with_api_key
  before_filter :redirect_to_root, :unless => :signed_in?

  def show
    respond_to do |format|
      format.html do
        @my_gems = current_user.rubygems
        @latest_updates = Version.subscribed_to_by(current_user).published(20)
        @subscribed_gems = current_user.subscribed_gems
      end
      format.atom do
        @versions = Version.subscribed_to_by(current_user).published(20)
        render 'versions/feed'
      end
    end
  end

end
