class OIDC::Provider < ApplicationRecord
  validate :issuer_match, if: :configuration
  before_validation -> { configuration&.expected_issuer = issuer }

  validates :configuration, nested: true
  validates :issuer, uniqueness: { ignore_case: true }

  has_many :api_key_roles, class_name: "OIDC::ApiKeyRole", inverse_of: :provider, foreign_key: :oidc_provider_id, dependent: :restrict_with_exception
  has_many :users, through: :api_key_roles, inverse_of: :oidc_providers
  has_many :id_tokens, through: :api_key_roles, inverse_of: :provider

  has_many :audits, as: :auditable, dependent: :nullify

  GITHUB_ACTIONS_ISSUER = "https://token.actions.githubusercontent.com".freeze

  def self.github_actions
    find_by(issuer: GITHUB_ACTIONS_ISSUER)
  end

  def github_actions?
    issuer == GITHUB_ACTIONS_ISSUER
  end

  class Configuration < ::OpenIDConnect::Discovery::Provider::Config::Response
    attr_optional required_attributes.delete(:authorization_endpoint)

    def initialize(hash)
      super(hash.deep_symbolize_keys)
    end

    def valid?
      super
      errors.delete(:authorization_endpoint, :blank)
      errors.none?
    end
  end

  attribute :configuration, Types::JsonDeserializable.new(Configuration)

  attribute :jwks, Types::JsonDeserializable.new(JSON::JWK::Set)

  def trusted_publisher_class
    case issuer
    when GITHUB_ACTIONS_ISSUER
      OIDC::TrustedPublisher::GitHubAction
    end
  end

  private

  def issuer_match
    return if issuer == configuration.issuer
    errors.add :configuration, "issuer (#{configuration.issuer}) does not match the provider issuer: #{issuer}"
  end
end
