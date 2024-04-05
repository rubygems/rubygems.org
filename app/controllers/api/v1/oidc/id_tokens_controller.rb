class Api::V1::OIDC::IdTokensController < Api::BaseController
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key

  def index
    render json: @api_key.user.oidc_id_tokens
  end

  def show
    render json: @api_key.user.oidc_id_tokens.find(params_fetch(:id))
  end
end
