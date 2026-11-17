# frozen_string_literal: true

module ApiKeyable
  extend ActiveSupport::Concern

  private

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

  def track_api_key_event(event, user, api_key = nil, **metadata)
    if api_key
      scope = api_key_scope(api_key)
      metadata = { "api_key.gid": api_key.to_gid.to_s, "api_key.scopes": scope[:scopes].join(","),
                   "api_key.gem": scope[:gem], "api_key.mfa": api_key.mfa, **metadata }
    end
    actor = user.log_actor_attributes.transform_keys { |key| :"actor.#{key}" }
    Datadog::Kit::AppSec::Events.track(event, "usr.id": user.id.to_s, **metadata.compact, **actor)
  rescue StandardError => e
    Rails.error.report(e, handled: true)
  end

  def api_key_scope(api_key)
    { scopes: api_key.scopes.sort, gem: api_key.rubygem&.name }
  end

  def track_api_key_scope_change(user, api_key, previous_scope)
    committed = ApiKey.find(api_key.id)
    return if api_key_scope(committed) == previous_scope

    track_api_key_event("api_key.scope_change.success", user, committed,
      "api_key.previous_scopes": previous_scope[:scopes].join(","), "api_key.previous_gem": previous_scope[:gem])
  rescue StandardError => e
    Rails.error.report(e, handled: true)
  end
end
