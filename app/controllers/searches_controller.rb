class SearchesController < ApplicationController

  def new
    if params[:query]
      @gems = Rubygem.search(params[:query])
    end
  end

end
