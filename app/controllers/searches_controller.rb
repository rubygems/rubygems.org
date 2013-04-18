class SearchesController < ApplicationController

  def show
    if params[:query]
      @gems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
      @exact_match = Rubygem.name_is(params[:query]).with_versions.first

      redirect_to rubygem_path(@exact_match) if @gems == [@exact_match]
    end
  end

end
