module JwtValidation
  extend ActiveSupport::Concern

  class UnsupportedIssuer < StandardError; end
  class UnverifiedJWT < StandardError; end
  class InvalidJWT < StandardError; end

  included do
    rescue_from InvalidJWT, with: :render_bad_request

    rescue_from(
      UnsupportedIssuer, UnverifiedJWT,
      JSON::JWT::VerificationFailed, JSON::JWK::Set::KidNotFound,
      OIDC::AccessPolicy::AccessError,
      with: :render_not_found
    )
  end

  def jwt_key_or_secret
    raise NotImplementedError
  end

  def decode_jwt
    @jwt = JSON::JWT.decode_compact_serialized(params.expect(:jwt), jwt_key_or_secret)
  rescue JSON::JWT::InvalidFormat, JSON::ParserError, ArgumentError => e
    # invalid base64 raises ArgumentError
    render_bad_request(e)
  end

  def validate_jwt_format
    %w[nbf iat exp].each do |claim|
      raise InvalidJWT, "Missing/invalid #{claim}" unless @jwt[claim].is_a?(Integer)
    end
    %w[iss jti].each do |claim|
      raise InvalidJWT, "Missing/invalid #{claim}" unless @jwt[claim].is_a?(String)
    end
  end

  def validate_provider
    raise UnsupportedIssuer, "Provider is missing jwks" if @provider.jwks.blank?
    # TODO: delete &. after all providers have updated their configuration
    return unless @provider.configuration_updated_at&.before?(1.day.ago)
    raise UnsupportedIssuer, "Configuration last updated too long ago: #{@provider.configuration_updated_at}"
  end

  def verify_jwt_time
    now = Time.now.to_i
    return if @jwt["nbf"] <= now && now < @jwt["exp"]
    raise UnverifiedJWT, "Invalid time"
  end
end
