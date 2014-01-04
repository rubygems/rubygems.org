class HomeController < ApplicationController
  def index
    @version = current_rubygems_release
    @rubygems_count  = Rubygem.total_count
    @downloads_count = Download.count
  end

  def current_rubygems_release
    if g = Rubygem.find_by_name("rubygems-update")
      if v = g.versions.release.indexed.by_created_at.first
        v.number
      else
        "0.0.0"
      end
    else
      "0.0.0"
    end
  end
end
