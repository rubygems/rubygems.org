class Api::V1::OIDC::ApiKeyRolesController < Api::BaseController
  include ApiKeyable

  before_action :set_api_key_role
  before_action :decode_jwt
  before_action :verify_jwt
  before_action :verify_access

  class UnverifiedJWT < StandardError
  end

  rescue_from JSON::JWS::VerificationFailed, UnverifiedJWT, OIDC::AccessPolicy::AccessError, with: :render_not_found

  def assume_role
    key = generate_unique_rubygems_key
    api_key = @api_key_role.user.api_keys.create!(
      hashed_key: hashed_key(key),
      name: "#{@api_key_role.name}-#{@jwt[:jti]}",
      **@api_key_role.api_key_permissions.create_params(@api_key_role.user)
    )
    Mailer.api_key_created(api_key.id).deliver_later
    render json: { rubygems_api_key: key, name: api_key.name, scopes: api_key.enabled_scopes, gem: api_key.rubygem }, status: :created
  end

  private

  def set_api_key_role
    @api_key_role = OIDC::ApiKeyRole.find(params.require(:id))
  end

  def decode_jwt
    @jwt = JSON::JWT.decode_compact_serialized(params.require(:jwt), @api_key_role.provider.jwks)
  rescue JSON::ParserError
    render_not_found
  end

  def verify_jwt
    raise UnverifiedJWT, "Issuer mismatch" unless @api_key_role.provider.issuer == @jwt["iss"]
    # TODO: test this
    raise UnverifiedJWT, "Invalid time" unless (@jwt["nbf"]..@jwt["exp"]).cover?(Time.now.to_i)
  end

  def verify_access
    @api_key_role.access_policy.verify_access!(@jwt)
  end
end
