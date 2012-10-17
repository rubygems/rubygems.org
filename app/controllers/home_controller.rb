class HomeController < ApplicationController
  def index
    @rubygems_count  = Rubygem.total_count
    @downloads_count = Download.count
  end
end
