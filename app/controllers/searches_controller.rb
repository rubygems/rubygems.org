class SearchesController < ApplicationController

  def new
    if params[:query]
      @gems = Rubygem.search(params[:query]).paginate(:page => params[:page])
    end
  end

end
