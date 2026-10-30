# frozen_string_literal: true

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
  before_action :find_asserted_owner

  rescue_from ActiveRecord::RecordInvalid do |err|
    render json: { errors: err.record.errors }, status: :unprocessable_content
  end

  # The DB unique index on (provider, jti) catches concurrent exchanges of the same token
  rescue_from ActiveRecord::RecordNotUnique do
    render json: { errors: { jti: ["must be unique"] } }, status: :unprocessable_content
  end

  def exchange_token
    key = generate_unique_rubygems_key
    iat = Time.at(@jwt[:iat].to_i, in: "UTC")
    api_key = nil
    ApiKey.transaction do
      api_key = @trusted_publisher.api_keys.create!(
        hashed_key: hashed_key(key),
        name: "#{@trusted_publisher.name} #{iat.iso8601}",
        scopes: %i[push_rubygem],
        expires_at: 15.minutes.from_now
      )
      # Records the jti so this token can only be exchanged once, and the account
      # the workflow asserted should own any gem this key creates.
      api_key.create_oidc_trusted_publisher_id_token!(
        provider: @provider,
        jti: @jwt[:jti],
        asserted_owner: @asserted_owner
      )
    end

    render json: {
      rubygems_api_key: key,
      name: api_key.name,
      scopes: api_key.scopes,
      gem: api_key.rubygem,
      owner: @asserted_owner&.handle,
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
    Current.api_key_owner = @trusted_publisher
  end

  def validate_claims
    @trusted_publisher.to_access_policy(@jwt).verify_access!(@jwt)
  end

  # Optional: the account whose pending trusted publisher may create a new gem with this
  # key. The workflow asserts it; the OIDC token proves the workflow is the repository's.
  def find_asserted_owner
    owner = params[:owner]
    return if owner.blank?
    return render_bad_request("Invalid owner") unless owner.is_a?(String)

    @asserted_owner = resolve_asserted_owner(owner)
    render_bad_request("Unknown owner #{owner.inspect}") if @asserted_owner.nil?
  end

  # All-digit references resolve as immutable IDs only: handles can be renamed and
  # re-registered, so a stale ID must fail rather than match a recycled handle.
  def resolve_asserted_owner(owner)
    if owner.match?(/\A\d+\z/)
      id = owner.to_i
      User.find_by(id: id) if id.bit_length <= 63
    else
      User.find_by("lower(handle) = ?", owner.downcase)
    end
  end
end
