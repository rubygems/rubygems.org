# frozen_string_literal: true

class StatsController < ApplicationController
  before_action -> { set_page Gemcutter::STATS_MAX_PAGES }

  def index
    @number_of_gems        = Rubygem.total_count
    @number_of_users       = User.count
    @number_of_downloads   = GemDownload.total_count
    @most_downloaded       = Rubygem.by_downloads.includes(:gem_download).page(@page).per(Gemcutter::STATS_PER_PAGE)
    @most_downloaded_count = GemDownload.most_downloaded_gem_count
    limit_total_count
  end

  private

  def limit_total_count
    class << @most_downloaded
      def total_count
        Gemcutter::STATS_MAX_PAGES * Gemcutter::STATS_PER_PAGE
      end
    end
  end
end
