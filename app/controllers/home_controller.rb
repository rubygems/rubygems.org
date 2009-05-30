class HomeController < ApplicationController
  def index
    @count = Rubygem.count
    @created_gems = Rubygem.by_created_at(:desc).limited(5)
    @updated_gems = Rubygem.by_updated_at(:desc).limited(5)
  end
end
