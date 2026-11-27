# frozen_string_literal: true

# An OIDC token exchanged for an API key at any endpoint, so each token is exchanged only once across all of
# them. The unique (provider, jti) index enforces that; each endpoint rescues the violation as a replay.
class OIDC::TokenExchange < ApplicationRecord
  SINGLE_USE_INDEXES = %w[
    index_oidc_token_exchanges_on_oidc_provider_id_and_jti
    index_oidc_id_tokens_on_issuer_and_jti
    index_oidc_trusted_publisher_id_tokens_on_provider_and_jti
  ].freeze

  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: :oidc_provider_id, inverse_of: :token_exchanges

  def self.replay?(error)
    SINGLE_USE_INDEXES.include?(error.cause&.result&.error_field(PG::PG_DIAG_CONSTRAINT_NAME))
  end
end
