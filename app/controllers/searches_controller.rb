class SearchesController < ApplicationController
  before_action :set_page, only: :show

  def show
    return unless params[:query] && params[:query].is_a?(String)
    begin
      @gems = Rubygem.search(params[:query], es: es_enabled?, page: @page)
    rescue RubygemSearchable::SearchDownError
      @fallback = true
      @gems = Rubygem.search(params[:query], es: false, page: @page)
    end
    @exact_match = Rubygem.name_is(params[:query]).with_versions.first
    redirect_to rubygem_path(@exact_match) if @gems == [@exact_match]
  end

  def autocomplete
    render json: Rubygem.search(params[:query], es: true).map(&:name)
  rescue RubygemSearchable::SearchDownError
    render json: []
  end

  private

  def es_enabled?
    cookies.permanent[:new_search] == 'true'
  end
end
