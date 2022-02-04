class Api::V1::ProfilesController < Api::BaseController
  def show
    @user = User.find_by_slug!(params[:id])
    respond_to do |format|
      format.json { render json: @user }
      format.yaml { render yaml: @user }
    end
  end

  def me
    authenticate_or_request_with_http_basic do |username, password|
      if (user = AuthenticatedUser.authenticate(username.strip, password))
        respond_to do |format|
          format.json { render json: user }
          format.yaml { render yaml: user }
        end
      end
    end
  end
end
