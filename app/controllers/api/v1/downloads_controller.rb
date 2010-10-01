class Api::V1::DownloadsController < Api::BaseController

  before_filter :find_gem, :only => [:show]

  def index
    render :json => {
      "total" => Download.count
    }
  end

  def show
    render :json => {
      "total_downloads" => @rubygem.downloads,
      "latest_version_downloads" => @rubygem.versions.most_recent.downloads_count
    }
  end

end
