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
                   "api_key.gem": scope[:gem_name], "api_key.mfa": api_key.mfa, **metadata }
    end
    actor = user.log_actor_attributes.transform_keys { |key| :"actor.#{key}" }
    Datadog::Kit::AppSec::Events.track(event, "usr.id": user.id.to_s, **metadata.compact, **actor)
  rescue StandardError => e
    Rails.error.report(e, handled: true)
  end

  def api_key_scope(api_key)
    gem = api_key.rubygem
    { scopes: api_key.scopes.sort, gem_id: gem&.id, gem_name: gem&.name }
  end

  def update_api_key_and_track_scope_change(user, api_key)
    previous_scope = persisted_key = nil
    updated = api_key.with_lock do
      previous_scope = api_key_scope(api_key)
      api_key.assign_attributes(yield)
      next false if api_key.errors.present?

      saved = api_key.transaction(requires_new: true) do
        api_key.save || raise(ActiveRecord::Rollback)
      end
      persisted_key = persisted_api_key_with_scope_change(api_key, previous_scope)
      saved
    end

    if persisted_key
      gem = persisted_key.rubygem
      previous_gem_name = gem&.id == previous_scope[:gem_id] ? gem&.name : previous_scope[:gem_name]
      track_api_key_event("api_key.scope_change.success", user, persisted_key,
        "api_key.previous_scopes": previous_scope[:scopes].join(","), "api_key.previous_gem": previous_gem_name)
    end
    updated
  end

  def persisted_api_key_with_scope_change(api_key, previous_scope)
    ApiKey.transaction(requires_new: true) do
      persisted = ApiKey.find(api_key.id)
      current_scope = api_key_scope(persisted)
      persisted if current_scope.values_at(:scopes, :gem_id) != previous_scope.values_at(:scopes, :gem_id)
    end
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    nil
  end
end
