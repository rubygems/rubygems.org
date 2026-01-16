class SearchesController < ApplicationController
  before_action -> { set_page Gemcutter::SEARCH_MAX_PAGES }, only: :show

  rescue_from SearchQuerySanitizer::QueryTooLongError,
              SearchQuerySanitizer::MalformedQueryError, with: :render_invalid_query

  def show
    return if params[:query].blank?
    @error_msg, @gems = ElasticSearcher.new(params[:query], page: @page).search

    return unless @gems
    set_total_pages if @gems.total_count > Gemcutter::SEARCH_MAX_PAGES * Rubygem.default_per_page
    exact_match = Rubygem.name_is(params[:query]).first
    @yanked_gem = exact_match unless exact_match&.indexed_versions?
    @yanked_filter = true if params[:yanked] == "true"
  end

  def advanced
  end

  private

  def render_invalid_query
    @error_msg = "Invalid search query. Please simplify your search and try again."
    render :show
  end

  def set_total_pages
    class << @gems
      def total_pages
        Gemcutter::SEARCH_MAX_PAGES
      end
    end
  end
end
