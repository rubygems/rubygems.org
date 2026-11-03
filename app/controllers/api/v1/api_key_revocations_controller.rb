# frozen_string_literal: true

class Api::V1::ApiKeyRevocationsController < Api::BaseController
  # Authenticate raw bytes before inherited callbacks access parsed parameters.
  prepend_before_action :authenticate_secret_scanning_request
  rescue_from ActionDispatch::Http::Parameters::ParseError, JSON::ParserError, with: :render_bad_request

  def revoke
    return revoke_truffle if @secret_scanning_provider == SecretScanning::Truffle

    # GitHub and deps.dev share this payload and classification response.
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
        label: result.key_found ? "true_positive" : "false_positive"
      }
    end

    respond_to do |format|
      format.json { render json: resp }
    end
  end

  private

  def revoke_truffle
    findings = JSON.parse(request.raw_post)
    fields = %w[id token type url source]
    valid = findings.is_a?(Array) && findings.all? do |finding|
      finding.is_a?(Hash) && fields.all? { |field| finding[field].is_a?(String) && finding[field].present? }
    end
    return render_bad_request("Expected an array of findings with nonempty id, token, type, url, and source strings") unless valid

    LeakedApiKeyRevocation.call(findings.map(&:symbolize_keys))
    head :no_content
  end

  def authenticate_secret_scanning_request
    @secret_scanning_provider = SecretScanning.authenticate!(request)
  rescue SecretScanning::AuthenticationError => e
    render plain: e.message, status: :unauthorized
  end
end
