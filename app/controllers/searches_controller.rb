class SearchesController < ApplicationController
  before_action -> { set_page Gemcutter::SEARCH_MAX_PAGES }, only: :show

  def show
    return unless params[:query]&.is_a?(String)
    @error_msg, @gems = ElasticSearcher.new(params[:query], page: @page).search
    limit_total_count if @gems.total_count > Gemcutter::SEARCH_MAX_PAGES * Rubygem.default_per_page
  end

  def advanced
  end

  private

  def limit_total_count
    class << @gems
      def total_count
        Gemcutter::SEARCH_MAX_PAGES * Rubygem.default_per_page
      end
    end
  end
end
