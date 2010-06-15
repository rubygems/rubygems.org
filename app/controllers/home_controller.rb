class HomeController < ApplicationController
  def index
    @rubygems_count  = Rubygem.total_count
    @downloads_count = Download.count
    @latest          = Rubygem.latest
    @downloaded      = Rubygem.downloaded
    @updated         = Version.updated
  end
end
