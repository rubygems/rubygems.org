class Api::V1::SearchesController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def show
    render :json => Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
  end

end
