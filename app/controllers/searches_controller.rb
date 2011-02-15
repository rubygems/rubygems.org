class SearchesController < ApplicationController

  def show
    if params[:query]
      @gems = Rubygem.search(params[:query], :page => params[:page])
      @exact_match = @gems.find { |g| g.name == params[:query] }
    end
  end

end
