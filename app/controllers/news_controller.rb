class NewsController < ApplicationController
  before_action :set_page

  def show
    @versions = Version.joins(:rubygem)
      .recent
      .indexed
      .by_created_at
      .paginate(page: @page, per_page: 10, total_entries: 100)
  end

  def popular
    @title = "New Releases — Popular Gems"
    @versions = Version.joins(:rubygem)
      .recent
      .indexed
      .by_created_at
      .merge(Rubygem.by_downloads)
      .paginate(page: @page, per_page: 10, total_entries: 100)

    render :show
  end
end
