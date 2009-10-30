class SearchesController < ApplicationController

  def new
    if params[:query]
      @gems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
      @exact_match = Rubygem.find(:first, :conditions => ["name = ?", params[:query]])
    end
  end

end
