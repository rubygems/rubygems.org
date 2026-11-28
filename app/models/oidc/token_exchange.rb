# frozen_string_literal: true

# An OIDC token exchanged for an API key at any endpoint, so each token is exchanged only once across all of
# them. The unique (provider, jti) index enforces that; each endpoint rescues the violation as a replay.
#
# A row matters only while its token can still be exchanged, and JwtValidation#verify_jwt_time refuses a token
# from its exp onwards. expires_at is that exp, so prune judges each row by its own token and never by the age
# of the row: a long-lived token keeps its row for as long as it lives.
class OIDC::TokenExchange < ApplicationRecord
  SINGLE_USE_INDEXES = %w[
    index_oidc_token_exchanges_on_oidc_provider_id_and_jti
    index_oidc_id_tokens_on_issuer_and_jti
    index_oidc_trusted_publisher_id_tokens_on_provider_and_jti
  ].freeze

  # Rows outlive their token by this much, for clock drift between hosts and for a request that passed
  # verify_jwt_time just before exp. Keep it above any leeway verify_jwt_time is ever given.
  PRUNE_GRACE = 1.hour

  # Postgres cannot store a timestamp past the year 294276. A token whose exp is later than 9999, such as a
  # never-expires sentinel, has its row kept until then, so the exchange is not refused over a date.
  LATEST_EXP = 253_402_300_799 # 9999-12-31T23:59:59Z

  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: :oidc_provider_id, inverse_of: :token_exchanges

  validates :expires_at, presence: true

  # Rows written before expires_at was recorded have none and never match, so they are kept.
  scope :prunable, -> { where(expires_at: ...PRUNE_GRACE.ago) }

  def self.replay?(error)
    SINGLE_USE_INDEXES.include?(error.cause&.result&.error_field(PG::PG_DIAG_CONSTRAINT_NAME))
  end

  # Every endpoint records an exchange through here, so each row carries its own token's exp.
  def self.record!(provider:, jwt:)
    create!(provider:, jti: jwt[:jti], expires_at: Time.zone.at([jwt[:exp], LATEST_EXP].min))
  end

  def self.prune
    prunable.in_batches(of: 1_000).delete_all
  end
end
