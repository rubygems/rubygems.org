# frozen_string_literal: true

class Api::V1::ApiKeyRevocationsController < Api::BaseController
  before_action :authenticate_secret_scanning_request

  # GitHub and deps.dev share this payload and classification response.
  def revoke
    # Preserve the original error order: validate and hash one finding at a time.
    tokens = params.expect(_json: [%i[token type url]]).lazy.map do |token|
      token.require(:token)
      token
    end
    resp = LeakedApiKeyRevocation.call(tokens).map do |result|
      t = result.finding

      {
        token_raw: t[:token],
        token_type: t[:type],
        label: result.expiration_result ? "true_positive" : "false_positive"
      }
    end

    respond_to do |format|
      format.json { render json: resp }
    end
  end

  private

  def authenticate_secret_scanning_request
    SecretScanning.authenticate!(request)
  rescue SecretScanning::AuthenticationError => e
    render plain: e.message, status: :unauthorized
  end
end
