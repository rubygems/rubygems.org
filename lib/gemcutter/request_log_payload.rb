# frozen_string_literal: true

# Builds the structured request log payload that SemanticLogger emits for
# every controller action. Included into ActionController by the
# semantic_logger initializer.
module Gemcutter::RequestLogPayload
  def append_info_to_payload(payload)
    payload.merge!(
      timestamp: Time.now.utc,
      env: Rails.env,
      edge_bypassed: request.edge_bypassed?,
      network: {
        client: {
          ip: request.ip
        }
      }
    )
    super

    payload[:rails] = log_payload_rails(payload)
    payload[:http] = log_payload_http

    identity = log_payload_identity
    payload[:identity] = identity if identity.any?

    payload[:message] ||= log_payload_message(payload)
  end

  private

  def log_payload_rails(payload)
    {
      controller: payload.fetch(:controller),
      action: payload.fetch(:action),
      params: request.filtered_parameters.except("controller", "action", "format", "utf8"),
      format: payload.fetch(:format),
      view_time_ms: payload.fetch(:view_runtime, 0.0),
      db_time_ms: payload.fetch(:db_runtime, 0.0)
    }
  end

  def log_payload_http
    {
      request_id: request.uuid,
      method: request.method,
      status_code: response.status,
      useragent: request.user_agent,
      url: request.url
    }
  end

  # Who is acting. `actor_gid` is the same GlobalID that
  # `Rack::Attack.api_key_owner_id` throttles on, so request logs join to
  # throttle logs. It covers a signed-in user, a user's API key, and a
  # trusted-publisher key alike; `actor_type` tells them apart.
  # `account_age_seconds` is nil (never 0) when there is no human, so a CI
  # push never reads as a brand-new account.
  def log_payload_identity
    api_key = log_payload_api_key
    user = api_key ? api_key.user : Current.user
    actor = api_key&.owner || user

    {
      user_id: user&.id,
      api_key_id: api_key&.id,
      actor_gid: actor&.to_gid&.to_s,
      actor_type: log_payload_actor_type(api_key, actor),
      account_age_seconds: user && (Time.current - user.created_at).to_i
    }.compact
  end

  def log_payload_api_key
    @api_key if @api_key.is_a?(ApiKey)
  end

  def log_payload_actor_type(api_key, actor)
    return "trusted_publisher" if api_key&.trusted_publisher?

    "user" if actor.is_a?(User)
  end

  # e.g. "[200] GET /gems/rails (RubygemsController#show)"
  def log_payload_message(payload)
    status = "[#{response.status}]"
    method_and_path = [request.method, request.path].compact_blank.join(" ").presence
    controller_action = "(#{payload.fetch(:controller)}##{payload.fetch(:action)})"

    [status, method_and_path, controller_action].compact.join(" ")
  end
end
