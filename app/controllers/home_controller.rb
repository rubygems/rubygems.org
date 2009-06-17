class HomeController < ApplicationController
  def index
    @count = Rubygem.with_versions.count
    @new = Rubygem.with_versions.by_created_at(:desc).limited(5)
    @updated = Version.by_created_at(:desc).limited(5)
    @downloaded = Rubygem.with_versions.by_downloads(:desc).limited(5)
  end
end
