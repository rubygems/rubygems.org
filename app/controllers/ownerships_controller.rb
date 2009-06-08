class OwnershipsController < ApplicationController
  before_filter :redirect_to_root, :unless => :signed_in?

  def show
    @ownership = Ownership.find(params[:id])
    response.content_type = "text/plain"
    render :text => @ownership.token
  end

end
