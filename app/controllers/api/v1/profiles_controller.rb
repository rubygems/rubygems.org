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
      if (user = User::WithPrivateFields.authenticate(username.strip, password))
        respond_to do |format|
          format.json { render json: user }
          format.yaml { render yaml: user }
        end
      else
        respond_to do |format|
          message = { error: "Invalid credentials", code: 401 }
          format.json { render json: message, status: :unauthorized }
          format.yaml { render yaml: message, status: :unauthorized }
        end
      end
    end
  end
end
