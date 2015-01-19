class SearchesController < ApplicationController
  before_filter :set_page, only: :show

  def show
    if params[:query]
      @gems = Rubygem.search(params[:query]).with_versions.paginate(page: @page)
      @exact_match = Rubygem.name_is(params[:query]).with_versions.first

      redirect_to rubygem_path(@exact_match) if @gems == [@exact_match]
    end
  end
end
