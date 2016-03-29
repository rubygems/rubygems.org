class StatsController < ApplicationController
  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = GemDownload.total_count
    @most_downloaded     = Rubygem.downloaded(10).includes(:gem_download)
    @most_downloaded_count = @most_downloaded.first.downloads
  end
end
