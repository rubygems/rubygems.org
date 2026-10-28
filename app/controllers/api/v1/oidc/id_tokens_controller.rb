# frozen_string_literal: true

class Api::V1::OIDC::IdTokensController < Api::BaseController
  before_action :deny_shared_cache
  before_action :authenticate_with_api_key
  before_action :verify_user_api_key

  def index
    authorize OIDC::IdToken, :index?
    render json: @api_key.user.oidc_id_tokens
  end

  def show
    # Authorize before the lookup so an unscoped key cannot tell a real id from an unknown one.
    authorize OIDC::IdToken, :show?
    render json: @api_key.user.oidc_id_tokens.find(params.expect(:id))
  end
end
