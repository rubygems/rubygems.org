# frozen_string_literal: true

class OIDC::IdToken < ApplicationRecord
  belongs_to :api_key_role, class_name: "OIDC::ApiKeyRole", foreign_key: :oidc_api_key_role_id, inverse_of: :id_tokens
  belongs_to :api_key, inverse_of: :oidc_id_token
  has_one :provider, through: :api_key_role, inverse_of: :id_tokens
  has_one :user, through: :api_key_role, inverse_of: :oidc_id_tokens

  validates :jwt, presence: true
  validates :jti, presence: true
  validate :jti_uniqueness

  def payload
    {
      api_key_role_token: api_key_role.token,
      jwt: jwt.slice("claims", "header")
    }
  end

  delegate :as_json, :to_yaml, to: :payload

  def to_xml(options = {})
    payload.to_xml(options.merge(root: "oidc:id_token"))
  end

  def jti
    jwt&.dig("claims", "jti")
  end

  def iss
    jwt&.dig("claims", "iss")
  end

  def claims
    jwt&.dig("claims")
  end

  def header
    jwt&.dig("header")
  end

  def jti_uniqueness
    return if iss.nil? || jti.nil?
    relation = self.class.where("jwt -> 'claims' ->> 'iss' = ? AND jwt -> 'claims' ->> 'jti' = ?", iss, jti)
    return unless relation.where.not(id: self).exists?
    errors.add("jwt.claims.jti", "must be unique")
  end
end
