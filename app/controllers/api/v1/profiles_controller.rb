class Api::V1::ProfilesController < Api::BaseController
  before_action :authenticate_user, only: [:me]

  def show
    @user = User.find_by_slug!(params[:id])
    respond_to do |format|
      format.json { render json: @user }
      format.yaml { render yaml: @user }
    end
  end

  def me
    respond_to do |format|
      format.json { render json: @user }
      format.yaml { render yaml: @user }
    end
  end

  private

  def authenticate_user
    authenticate_or_request_with_http_basic do |username, password|
      @user = AuthenticatedUser.authenticate(username.strip, password)
    end
  end
end
