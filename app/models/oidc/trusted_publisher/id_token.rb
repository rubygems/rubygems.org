# frozen_string_literal: true

# An OIDC ID token exchanged for a short-lived API key. The per-provider jti makes each token
# single-use; asserted_owner is the account the workflow declared should own any gem the key creates.
class OIDC::TrustedPublisher::IdToken < ApplicationRecord
  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: :oidc_provider_id, inverse_of: :trusted_publisher_id_tokens
  belongs_to :api_key, optional: true, inverse_of: :oidc_trusted_publisher_id_token
  belongs_to :asserted_owner, class_name: "User", optional: true, inverse_of: false

  validates :jti, presence: true, uniqueness: { scope: :oidc_provider_id }
end
