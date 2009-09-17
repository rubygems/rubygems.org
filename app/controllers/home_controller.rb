class HomeController < ApplicationController
  def index
    @count = Rubygem.total_count
    @latest = Rubygem.latest
    @downloaded = Rubygem.downloaded
    @updated = Version.release.published
  end
end
