# frozen_string_literal: true

class LeakedApiKeyRevocation
  Result = Data.define(:finding, :key_found)

  # Findings must be authenticated and validated by the caller. Duplicate tokens
  # use the last finding's metadata, and are revoked and notified once per batch.
  def self.call(findings)
    tokens = findings.index_by { |finding| Digest::SHA256.hexdigest(finding.fetch(:token)) }
    api_keys = ApiKey.where(hashed_key: tokens.keys).index_by(&:hashed_key)

    tokens.map do |hashed_key, finding|
      api_key = api_keys[hashed_key]
      api_key&.with_lock do
        next if api_key.expired?

        api_key.expire!
        Mailer.api_key_revoked(api_key.owner_id, api_key.name, api_key.scopes.join(", "), finding[:url]).deliver_later if api_key.user?
      end

      Result.new(finding:, key_found: api_key.present?)
    end
  end
end
