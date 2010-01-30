class Api::V1::SearchesController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def show
    @gems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
    respond_to do |wants|
      wants.json { render :json => @gems }
      wants.xml  { render :xml  => @gems }
    end
  end

end
