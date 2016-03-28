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
    data = {
      gems: Download.most_downloaded_all_time(50).map do |version, count|
        [version.attributes, count]
      end
    }
    respond_with_data(data)
  end

  private

  def respond_with_data(data)
    respond_to do |format|
      format.json { render json: data }
      format.yaml { render text: data.to_yaml }
    end
  end
end
