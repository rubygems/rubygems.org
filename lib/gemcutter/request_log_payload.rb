# frozen_string_literal: true

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

  # During an OIDC token exchange there's no key yet, so the owner is the
  # publisher being issued one.
  def log_payload_identity
    api_key = Current.api_key
    owner = api_key ? api_key.owner : Current.api_key_owner
    user = Current.user

    {
      user_id: user&.id,
      api_key_id: api_key&.id,
      api_key_owner_type: owner&.class&.polymorphic_name,
      api_key_owner_id: owner&.id,
      admin_github_user_id: request.get_header("gemcutter.rubygems_admin_oauth_github_user")&.id,
      **log_payload_actor(owner || user, user)
    }.compact
  end

  def log_payload_actor(actor, user)
    {
      actor_gid: actor&.to_gid&.to_s,
      actor_type: log_payload_actor_type(actor),
      account_age_seconds: user && (Time.current - user.created_at).to_i
    }
  end

  def log_payload_actor_type(actor)
    case actor
    when nil then nil
    when User then "user"
    else "trusted_publisher"
    end
  end

  # e.g. "[200] GET /gems/rails (RubygemsController#show)"
  def log_payload_message(payload)
    status = "[#{response.status}]"
    method_and_path = [request.method, request.path].compact_blank.join(" ").presence
    controller_action = "(#{payload.fetch(:controller)}##{payload.fetch(:action)})"

    [status, method_and_path, controller_action].compact.join(" ")
  end
end
