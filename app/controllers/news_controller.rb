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
    popular_gem_ids = Rubygem.by_downloads.limit(100).pluck(:id).uniq

    @versions = Version.recent
      .indexed
      .by_created_at
      .where(rubygem_id: popular_gem_ids)
      .paginate(page: @page, per_page: 10, total_entries: 100)

    render :show
  end
end
