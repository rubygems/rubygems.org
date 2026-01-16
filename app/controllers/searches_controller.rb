class SearchesController < ApplicationController
  before_action -> { set_page Gemcutter::SEARCH_MAX_PAGES }, only: :show
  before_action :sanitize_query, only: :show

  def show
    return if @sanitized_query.blank?
    @error_msg, @gems = ElasticSearcher.new(@sanitized_query, page: @page).search

    return unless @gems
    set_total_pages if @gems.total_count > Gemcutter::SEARCH_MAX_PAGES * Rubygem.default_per_page
    exact_match = Rubygem.name_is(params[:query]).first
    @yanked_gem = exact_match unless exact_match&.indexed_versions?
    @yanked_filter = true if params[:yanked] == "true"
  end

  def advanced
  end

  private

  def sanitize_query
    @sanitized_query = SearchQuerySanitizer.sanitize(params[:query])
  rescue SearchQuerySanitizer::QueryTooLongError, SearchQuerySanitizer::MalformedQueryError
    @error_msg = "Invalid search query. Please simplify your search and try again."
    @sanitized_query = nil
  end

  def set_total_pages
    class << @gems
      def total_pages
        Gemcutter::SEARCH_MAX_PAGES
      end
    end
  end
end
