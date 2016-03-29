class Api::V1::DownloadsController < Api::BaseController
  def index
    total = GemDownload.total_count
    respond_to do |format|
      format.any(:all) { render text: total }
      format.json { render json: { total: total } }
      format.yaml { render text: { total: total }.to_yaml }
    end
  end

  def show
    full_name = params[:id]
    version = Version.find_by(full_name: full_name)
    if version && !version.yanked?
      data = {
        total_downloads: GemDownload.count_for_rubygem(version.rubygem_id),
        version_downloads: GemDownload.count_for_version(version.id)
      }
      respond_with_data(data)
    else
      render text: t(:this_rubygem_could_not_be_found), status: :not_found
    end
  end

  def top
    render text: "This endpoint is not supported anymore", status: :not_found
  end

  def all
    gems = GemDownload.where("version_id != 0").includes(:version).order(count: :desc).limit(50)
    gems = gems.map do |gem|
      next unless gem.version
      [gem.version.attributes, gem.count]
    end.compact
    respond_with_data(gems: gems)
  end

  private

  def respond_with_data(data)
    respond_to do |format|
      format.json { render json: data }
      format.yaml { render text: data.to_yaml }
    end
  end
end
