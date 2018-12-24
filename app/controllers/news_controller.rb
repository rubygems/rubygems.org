# frozen_string_literal: true

class NewsController < ApplicationController
  before_action -> { set_page Gemcutter::NEWS_MAX_PAGES }

  def show
    @rubygems = Rubygem.news(Gemcutter::NEWS_DAYS_LIMIT).page(@page).per(Gemcutter::NEWS_PER_PAGE)
    limit_total_count
  end

  def popular
    @title = t(".title")
    @rubygems = Rubygem.by_downloads.news(Gemcutter::POPULAR_DAYS_LIMIT).page(@page).per(Gemcutter::NEWS_PER_PAGE)
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
