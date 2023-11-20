class Api::V1::OIDC::ApiKeyRolesController < Api::BaseController
  include ApiKeyable

  before_action :authenticate_with_api_key, except: :assume_role
  before_action :verify_user_api_key, except: :assume_role

  with_options only: :assume_role do
    before_action :set_api_key_role
    before_action :decode_jwt
    before_action :verify_jwt
    before_action :verify_access
  end

  class UnverifiedJWT < StandardError
  end

  rescue_from(
    UnverifiedJWT,
    JSON::JWT::VerificationFailed, JSON::JWK::Set::KidNotFound,
    OIDC::AccessPolicy::AccessError,
    with: :render_not_found
  )

  rescue_from ActiveRecord::RecordInvalid do |err|
    render json: {
      errors: err.record.errors
    }, status: :unprocessable_entity
  end

  def index
    render json: @api_key.user.oidc_api_key_roles
  end

  def show
    render json: @api_key.user.oidc_api_key_roles.find_by!(token: params.require(:token))
  end

  def assume_role
    key = nil
    api_key = nil
    ApiKey.transaction do
      key = generate_unique_rubygems_key
      api_key = @api_key_role.user.api_keys.create!(
        hashed_key: hashed_key(key),
        name: "#{@api_key_role.name}-#{@jwt[:jti]}",
        **@api_key_role.api_key_permissions.create_params(@api_key_role.user)
      )
      OIDC::IdToken.create!(
        api_key:,
        jwt: { claims: @jwt, header: @jwt.header },
        api_key_role: @api_key_role,
        provider: @api_key_role.provider
      )
      Mailer.api_key_created(api_key.id).deliver_later
    end

    render json: {
      rubygems_api_key: key,
      name: api_key.name,
      scopes: api_key.enabled_scopes,
      gem: api_key.rubygem,
      expires_at: api_key.expires_at
    }.compact, status: :created
  end

  private

  def set_api_key_role
    @api_key_role = OIDC::ApiKeyRole.active.find_by!(token: params.require(:token))
  end

  def decode_jwt
    @jwt = JSON::JWT.decode_compact_serialized(params.require(:jwt), @api_key_role.provider.jwks)
  rescue JSON::ParserError
    raise UnverifiedJWT, "Invalid JSON"
  end

  def verify_jwt
    raise UnverifiedJWT, "Issuer mismatch" unless @api_key_role.provider.issuer == @jwt["iss"]
    raise UnverifiedJWT, "Invalid time" unless (@jwt["nbf"]..@jwt["exp"]).cover?(Time.now.to_i)
  end

  def verify_access
    @api_key_role.access_policy.verify_access!(@jwt)
  end
end
