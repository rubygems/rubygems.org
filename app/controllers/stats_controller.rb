class StatsController < ApplicationController
  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = Download.count
    @most_downloaded     = Rubygem.downloaded
    @most_downloaded_count = @most_downloaded.first.downloads
  end
end
