class Api::V1::DownloadsController < Api::BaseController
  respond_to :json, :xml, :yaml

  def index
    count = Download.count
    respond_with(:total => count) do |format|
      format.html { render :text => count }
    end
  end

  def show
    full_name = params[:id]
    if rubygem_name = Version.rubygem_name_for(full_name)
      respond_with(
        :total_downloads   => Download.for_rubygem(rubygem_name),
        :version_downloads => Download.for_version(full_name)
      )
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

  def top
    respond_with(
      :gems => Download.most_downloaded_today(50).map {|version, count|
        [version.attributes, count]
      }
    )
  end

end
