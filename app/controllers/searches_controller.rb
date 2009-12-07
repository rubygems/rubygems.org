class SearchesController < ApplicationController

  def new
    if params[:query]
      @gems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
      @exact_match = Rubygem.name_is(params[:query]).with_versions.first
    end
  end

end
