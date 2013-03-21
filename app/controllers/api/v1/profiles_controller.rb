class Api::V1::ProfilesController < Api::BaseController
  respond_to :json, :only => [:show]

  def show
    respond_with User.find_by_slug!(params[:id])
  end
end
