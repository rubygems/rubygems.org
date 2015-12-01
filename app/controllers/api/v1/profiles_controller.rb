class Api::V1::ProfilesController < Api::BaseController
  def show
    @user = User.find_by_slug!(params[:id])
    respond_to do |format|
      format.json { render json: @user, serializer: UserSerializer }
      format.yaml { render yaml: @user, serializer: UserSerializer }
    end
  end
end
