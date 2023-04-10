class OIDC::IdToken < ApplicationRecord
  belongs_to :api_key_role, class_name: "OIDC::ApiKeyRole", foreign_key: "oidc_api_key_role_id", inverse_of: :id_tokens
  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: "oidc_provider_id", inverse_of: :api_key_roles
  belongs_to :api_key, inverse_of: :oidc_id_token
  has_one :user, through: :api_key_role

  # TODO: validate provider / jti is unique
  validate :jti_uniqueness

  def jti
    jwt.dig("claims", "jti")
  end

  def jti_uniqueness
    return unless self.class.where(provider_id:).where("(jwt->>'claims')::jsonb->>'jti' = ?", jti).where.not(id: self).exists?
    errors.add("jwt.claims.jti", "must be unique")
  end
end
