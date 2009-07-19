class SearchesController < ApplicationController

  def new
    if params[:query]
      @gems = Rubygem.name_matches(params[:query])
    end
  end

end
