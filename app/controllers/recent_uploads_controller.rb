class RecentUploadsController < ApplicationController
  def index
    @recent_uploads = Version.recent_uploads(25)
  end
end
