class HomeController < ApplicationController
  def index
    @version = Rubygem.current_rubygems_release
    @rubygems_count  = Rubygem.total_count
    @downloads_count = Download.count
  end

end
