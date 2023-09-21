class RefreshOIDCProviderJob < ApplicationJob
  queue_as :default

  ERRORS = (HTTP_ERRORS + [Faraday::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError]).freeze
  retry_on(*ERRORS)

  def perform(provider:)
    connection = Faraday.new(provider.issuer, request: { timeout: 2 }, headers: { "Accept" => "application/json" }) do |f|
      f.request :json
      f.response :logger, logger, headers: false, errors: true, bodies: true
      f.response :raise_error
      f.response :json, content_type: //
    end
    resp = connection.get("/.well-known/openid-configuration")

    provider.configuration = resp.body
    provider.configuration.validate!
    provider.jwks = connection.get(provider.configuration.jwks_uri).body

    provider.save!
  end
end
