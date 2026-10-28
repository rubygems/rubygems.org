# frozen_string_literal: true

class LeakedApiKeyRevocation
  # Preserve ApiKey#expire!'s return value for caller-specific reporting. It can
  # be nil even when a trusted publisher's key was expired successfully.
  Result = Data.define(:finding, :expiration_result)

  # Findings must be authenticated and validated by the caller. Duplicate tokens
  # use the last finding's metadata, and are revoked and notified once per batch.
  def self.call(findings)
    tokens = findings.index_by { |finding| Digest::SHA256.hexdigest(finding.fetch(:token)) }
    api_keys = ApiKey.where(hashed_key: tokens.keys).index_by(&:hashed_key)

    tokens.map do |hashed_key, finding|
      api_key = api_keys[hashed_key]
      expiration_result = api_key&.expire!
      if expiration_result && api_key.user?
        Mailer.api_key_revoked(api_key.owner_id, api_key.name, api_key.scopes.join(", "), finding[:url]).deliver_later
      end

      Result.new(finding:, expiration_result:)
    end
  end
end
