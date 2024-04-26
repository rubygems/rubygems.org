class Api::V1::OIDC::ProvidersController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key

  def index
    render json: OIDC::Provider.all
  end

  def show
    render json: OIDC::Provider.find(params.permit(:id).require(:id))
  end
end
