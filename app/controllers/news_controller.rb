class NewsController < ApplicationController
  before_action :set_page

  def show
    @rubgyems = Rubygem.news(7.days)
      .paginate(page: @page, per_page: 10, total_entries: 100)
  end

  def popular
    @title = t(".title")

    @rubgyems = Rubygem.by_downloads
      .news(70.days)
      .paginate(page: @page, per_page: 10, total_entries: 100)

    render :show
  end
end
