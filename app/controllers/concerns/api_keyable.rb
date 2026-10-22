# frozen_string_literal: true

module ApiKeyable
  extend ActiveSupport::Concern

  private

  def track_api_key_event(event, api_key)
    track_appsec_event(event, user: api_key.user, "api_key.id": api_key.id.to_s,
      "api_key.scopes": api_key.scopes.sort.join(","), "api_key.mfa": api_key.mfa.to_s,
      "api_key.rubygem_id": api_key.rubygem_id&.to_s)
  end

  def hashed_key(key)
    Digest::SHA256.hexdigest(key)
  end

  def generate_unique_rubygems_key
    loop do
      key = generate_rubygems_key
      return key if ApiKey.where(hashed_key: hashed_key(key)).empty?
    end
  end

  def generate_rubygems_key
    "rubygems_#{SecureRandom.hex(24)}"
  end

  def legacy_key_defaults
    legacy_scopes = ApiKey::API_SCOPES - ApiKey::EXCLUSIVE_SCOPES
    { scopes: legacy_scopes, name: "legacy-key" }
  end
end
