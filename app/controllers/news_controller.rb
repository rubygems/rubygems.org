class NewsController < ApplicationController
  before_action -> { set_page Gemcutter::NEWS_MAX_PAGES }

  def show
    @rubygems_pagy, @rubygems = pagy(
      Rubygem.preload(:latest_version, :gem_download)
      .news(Gemcutter::NEWS_DAYS_LIMIT),
      limit: Gemcutter::NEWS_MAX_PAGES
    )

    limit_total_count
  end

  def popular
    @title = t(".title")
    @rubygems_pagy, @rubygems = pagy(Rubygem.preload(:latest_version, :gem_download)
      .popular(Gemcutter::POPULAR_DAYS_LIMIT),
      limit: Gemcutter::NEWS_MAX_PAGES)
    limit_total_count

    render :show
  end

  private

  def limit_total_count
    class << @rubygems
      def total_count
        Gemcutter::NEWS_MAX_PAGES * Gemcutter::NEWS_PER_PAGE
      end
    end
  end
end
