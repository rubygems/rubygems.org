class SearchesController < ApplicationController
  before_action -> { set_page Gemcutter::SEARCH_MAX_PAGES }, only: :show

  def show
    return unless params[:query]&.is_a?(String)
    @error_msg, @gems = ElasticSearcher.new(params[:query], page: @page).search

    set_total_pages if @gems.total_count > Gemcutter::SEARCH_MAX_PAGES * Rubygem.default_per_page
    exact_match = Rubygem.name_is(params[:query]).first
    @yanked_gem = exact_match unless exact_match&.indexed_versions?
    @yanked_filter = true if params[:yanked] == "true"
  end

  def advanced
  end

  private

  def set_total_pages
    class << @gems
      def total_pages
        Gemcutter::SEARCH_MAX_PAGES
      end
    end
  end
end
