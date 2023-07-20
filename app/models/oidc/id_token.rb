class OIDC::IdToken < ApplicationRecord
  belongs_to :api_key_role, class_name: "OIDC::ApiKeyRole", foreign_key: "oidc_api_key_role_id", inverse_of: :id_tokens
  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: "oidc_provider_id", inverse_of: :id_tokens
  belongs_to :api_key, inverse_of: :oidc_id_token
  has_one :user, through: :api_key_role, inverse_of: :oidc_id_tokens

  validates :jwt, presence: true
  validate :jti_uniqueness

  def payload
    {
      provider_id: oidc_provider_id,
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
    return unless self.class.where(oidc_provider_id:).where("(jwt->>'claims')::jsonb->>'jti' = ?", jti).where.not(id: self).exists?
    errors.add("jwt.claims.jti", "must be unique")
  end
end
