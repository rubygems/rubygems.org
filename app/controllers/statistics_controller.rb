class StatisticsController < ApplicationController
  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = Rubygem.sum('downloads')
  end
end
