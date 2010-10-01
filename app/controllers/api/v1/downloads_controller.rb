class Api::V1::DownloadsController < Api::BaseController

  def index
    render :json => {
      "total" => Download.count
    }
  end

  def show
    if rubygem_name = Version.rubygem_name_for(params[:id])
      render :json => {
        "total_downloads"   => Download.for_rubygem(rubygem_name),
        "version_downloads" => Download.for_version(params[:id])
      }
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

end
