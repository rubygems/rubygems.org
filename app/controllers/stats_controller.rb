class StatsController < ApplicationController
  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = Download.count

    if Rails.application.config.stats_page_top_10_from_redis
      @most_downloaded = Rubygem.downloaded(10)
      _, @most_downloaded_count = @most_downloaded.first
    else
      @most_downloaded = Rubygem.downloaded(10).sort_by(&:downloads).reverse!
      @most_downloaded_count = @most_downloaded.first.downloads
    end
  end
end
