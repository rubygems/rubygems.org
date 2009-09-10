class SearchesController < ApplicationController

  def new
    if params[:query]
      @gems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
    end
  end

end
