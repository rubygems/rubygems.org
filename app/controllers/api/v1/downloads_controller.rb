class Api::V1::DownloadsController < Api::BaseController
  def index
    total = GemDownload.total_count
    respond_to do |format|
      format.any(:all) { render plain: total }
      format.json { render json: { total: total } }
      format.yaml { render plain: { total: total }.to_yaml }
    end
  end

  def show
    full_name = params[:id]
    version = Version.find_by(full_name: full_name)
    if version
      data = {
        total_downloads: GemDownload.count_for_rubygem(version.rubygem_id),
        version_downloads: GemDownload.count_for_version(version.id)
      }
      respond_with_data(data)
    else
      render plain: t(:this_rubygem_could_not_be_found), status: :not_found
    end
  end

  def top
    render plain: "This endpoint is not supported anymore", status: :gone
  end

  def all
    gems = GemDownload.most_downloaded_gems.limit(50)
    gems = gems.filter_map do |gem|
      next unless gem.version
      [gem.version.attributes, gem.count]
    end
    respond_with_data(gems: gems)
  end

  private

  def respond_with_data(data)
    respond_to do |format|
      format.json { render json: data }
      format.yaml { render plain: data.to_yaml }
    end
  end
end
