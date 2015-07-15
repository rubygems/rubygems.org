class Api::V1::ProfilesController < Api::BaseController
  def show
    respond_to do |format|
      format.json { render json: User.find_by_slug!(params[:id]) }
    end
  end
end
