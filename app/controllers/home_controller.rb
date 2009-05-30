class HomeController < ApplicationController
  def index
    @count = Rubygem.count
    @new = Rubygem.by_created_at(:desc).limited(5)
    @updated = Version.by_created_at(:desc).limited(5)
    @downloaded = Rubygem.by_downloads(:desc).limited(5)
  end
end
