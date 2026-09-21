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

    actor = log_payload_actor
    payload[:actor] = actor if actor

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

  # Only principals whose credentials were verified are logged; a later 403
  # does not remove them. The owner is the authenticating key's polymorphic
  # owner (User or a trusted publisher) or, during an OIDC token exchange
  # where no key exists yet, the publisher the key is being issued to.
  # The admin user is the Admin::GitHubUser that Gemcutter::Middleware::AdminAuth
  # stores on the request env (see GitHubOAuthable#admin_user_request_header).
  def log_payload_identity
    api_key = Current.api_key
    owner = log_payload_owner

    {
      user_id: Current.user&.id,
      api_key_id: api_key&.id,
      api_key_owner_type: owner&.class&.polymorphic_name,
      api_key_owner_id: owner&.id,
      admin_github_user_id: request.get_header("gemcutter.rubygems_admin_oauth_github_user")&.id
    }.compact
  end

  # Who is acting, in the same shape as the `actor` block on gem.push.* log
  # lines so that one facet keys detection rules across every line.
  def log_payload_actor
    (log_payload_owner || Current.user)&.log_actor_attributes
  end

  def log_payload_owner
    api_key = Current.api_key
    api_key ? api_key.owner : Current.api_key_owner
  end

  # e.g. "[200] GET /gems/rails (RubygemsController#show)"
  def log_payload_message(payload)
    status = "[#{response.status}]"
    method_and_path = [request.method, request.path].compact_blank.join(" ").presence
    controller_action = "(#{payload.fetch(:controller)}##{payload.fetch(:action)})"

    [status, method_and_path, controller_action].compact.join(" ")
  end
end
