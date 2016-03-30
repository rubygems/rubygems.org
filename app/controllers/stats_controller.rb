class StatsController < ApplicationController
  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = GemDownload.total_count
    @most_downloaded     = Rubygem.by_downloads.limit(10).includes(:gem_download).to_a
    @most_downloaded_count = @most_downloaded.first.gem_download.count
  end
end
