class SearchesController < ApplicationController
  before_action :set_page, :limit_page, only: :show
  # Limit max page as ES result window is upper bounded by 10_000 records
  MAX_PAGE = 100

  def show
    return unless params[:query] && params[:query].is_a?(String)
    @error_msg, @gems = Rubygem.search(params[:query], es: es_enabled?, page: @page)
    limit_total_entries if @gems.total_entries > MAX_PAGE * Rubygem.per_page

    @all_gems =  @gems.reject { |gem| gem == @gems.first }
    @exact_match = Rubygem.name_is(params[:query]).with_versions.first
    redirect_to rubygem_path(@exact_match) if @exact_match && @gems.size == 1
  end

  def advanced
  end

  private

  def limit_page
    render_404 if @page > MAX_PAGE
  end

  def limit_total_entries
    class << @gems
      def total_entries
        MAX_PAGE * Rubygem.per_page
      end
    end
  end

  def es_enabled?
    true
  end
end
