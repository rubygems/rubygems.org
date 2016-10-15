class StatsController < ApplicationController
  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = GemDownload.total_count
    @most_downloaded     = Rubygem.by_downloads
      .includes(:gem_download)
      .paginate(page: params[:page], per_page: 10, total_entries: 100)
    @most_downloaded_count = GemDownload.most_downloaded_gem_count
  end
end
