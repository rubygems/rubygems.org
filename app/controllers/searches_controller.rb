class SearchesController < ApplicationController

  def show
    if params[:query]
      @gems = Rubygem.tire.search "*#{params[:query]}* AND indexed:true",
                                  :page     => params[:page],
                                  :per_page => Rubygem.per_page,
                                  :load     => {:include => 'versions'}
      @exact_match = Rubygem.name_is(params[:query]).with_versions.first

      redirect_to rubygem_path(@exact_match) if @exact_match && @gems.size == 1 && @gems.first.id == @exact_match.id
    end
  end

end
