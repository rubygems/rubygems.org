class OIDC::IdToken < ApplicationRecord
  belongs_to :api_key_role, class_name: "OIDC::ApiKeyRole", foreign_key: "oidc_api_key_role_id", inverse_of: :id_tokens
  belongs_to :api_key, inverse_of: :oidc_id_token
  has_one :provider, through: :api_key_role, inverse_of: :id_tokens
  has_one :user, through: :api_key_role, inverse_of: :oidc_id_tokens

  validates :jwt, presence: true
  validate :jti_uniqueness

  def self.provider_id(oidc_provider_id)
    joins(:api_key_role).where(api_key_role: { oidc_provider_id: })
  end

  def payload
    {
      api_key_role_token: api_key_role.token,
      jwt: jwt.slice("claims", "header")
    }
  end

  def as_json(*args)
    payload.as_json(*args)
  end

  def to_xml(options = {})
    payload.to_xml(options.merge(root: "oidc:id_token"))
  end

  def to_yaml(*args)
    payload.to_yaml(*args)
  end

  def jti
    jwt&.dig("claims", "jti")
  end

  def jti_uniqueness
    relation = self.class.where("(jwt->>'claims')::jsonb->>'jti' = ?", jti)
    relation = relation.provider_id(api_key_role.oidc_provider_id) if api_key_role
    return unless relation.where.not(id: self).exists?
    errors.add("jwt.claims.jti", "must be unique")
  end
end
