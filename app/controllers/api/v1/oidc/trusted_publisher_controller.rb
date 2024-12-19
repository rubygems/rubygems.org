class Api::V1::OIDC::TrustedPublisherController < Api::BaseController
  include ApiKeyable
  include JwtValidation

  before_action :decode_jwt
  before_action :validate_jwt_format
  before_action :verify_jwt_time
  before_action :find_provider
  before_action :validate_provider
  before_action :verify_signature
  before_action :find_trusted_publisher
  before_action :validate_claims

  def exchange_token
    key = generate_unique_rubygems_key
    iat = Time.at(@jwt[:iat].to_i, in: "UTC")
    api_key = @trusted_publisher.api_keys.create!(
      hashed_key: hashed_key(key),
      name: "#{@trusted_publisher.name} #{iat.iso8601}",
      scopes: %i[push_rubygem],
      expires_at: 15.minutes.from_now
    )

    render json: {
      rubygems_api_key: key,
      name: api_key.name,
      scopes: api_key.scopes,
      gem: api_key.rubygem,
      expires_at: api_key.expires_at
    }.compact, status: :created
  end

  private

  def jwt_key_or_secret
    :skip_verification
  end

  def find_provider
    @provider = OIDC::Provider.find_by!(issuer: @jwt[:iss])
  end

  def verify_signature
    @jwt.verify!(@provider.jwks)
  end

  def find_trusted_publisher
    unless (trusted_publisher_class = @provider.trusted_publisher_class)
      raise UnsupportedIssuer, "Unsuported issuer for trusted publishing"
    end
    @trusted_publisher = trusted_publisher_class.for_claims(@jwt)
  end

  def validate_claims
    @trusted_publisher.to_access_policy(@jwt).verify_access!(@jwt)
  end
end
