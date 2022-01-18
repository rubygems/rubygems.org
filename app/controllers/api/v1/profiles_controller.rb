class Api::V1::ProfilesController < Api::BaseController

  def show
    if params[:id]
      show_public_profile
    else
      show_private_profile
    end
  end

  private

  def show_public_profile
    user = User.find_by_slug!(params[:id])
    respond_with(user)
  end

  def show_private_profile
    authenticate_or_request_with_http_basic do |username, password|
      if (user = User.authenticate(username.strip, password))
        respond_with(user.private_payload)
      end
    end
  end

  def respond_with(response)
    respond_to do |format|
      format.json { render json: response }
      format.yaml { render yaml: response }
    end
  end
end
