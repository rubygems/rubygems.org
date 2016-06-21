class Api::V1::ApiKeysController < Api::BaseController
  before_action :verify_authenticity_token, only: :reset
  before_action :redirect_to_root, unless: :signed_in?, only: [:reset]

  def show
    authenticate_or_request_with_http_basic do |username, password|
      sign_in User.authenticate(username, password)
      if current_user
        respond_to do |format|
          format.any(:all) { render text: current_user.api_key }
          format.json { render json: { rubygems_api_key: current_user.api_key } }
          format.yaml { render text: { rubygems_api_key: current_user.api_key }.to_yaml }
        end
      else
        false
      end
    end
  end

  def reset
    current_user.reset_api_key!
    flash[:notice] =
      "Your API key has been reset. Don't forget to update your ~/.gem/credentials file!"
    redirect_to edit_profile_path
  end
end
