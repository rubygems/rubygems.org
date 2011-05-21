class HomeController < ApplicationController
  def index
    @rubygems_count  = Rubygem.total_count
    @downloads_count = Download.count
    @latest          = Rubygem.latest
    @downloaded      = Download.most_downloaded_today
    @updated         = Version.just_updated
  end
end
