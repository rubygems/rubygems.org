# frozen_string_literal: true

SemanticLogger.application = "rubygems.org"

ActiveSupport.on_load(:action_controller) do
  def append_info_to_payload(payload)
    payload.merge!(
      timestamp: Time.now.utc,
      env: Rails.env,
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

  def log_payload_rails(payload)
    {
      controller: payload.fetch(:controller),
      action: payload.fetch(:action),
      params: request.filtered_parameters.except('controller', 'action', 'format', 'utf8'),
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
  def log_payload_identity
    api_key = Current.api_key
    owner = Current.api_key_owner
    {
      user_id: Current.user&.id,
      api_key_id: api_key&.id,
      api_key_owner_type: api_key ? api_key.owner_type : owner&.class&.polymorphic_name,
      api_key_owner_id: api_key ? api_key.owner_id : owner&.id,
      admin_github_user_id: request.get_header(GitHubOAuthable::ADMIN_USER_REQUEST_HEADER)&.id
    }.compact
  end

  # e.g. "[200] GET /gems/rails (RubygemsController#show)"
  def log_payload_message(payload)
    status = "[#{response.status}]"
    method_and_path = [request.method, request.path].compact_blank.join(' ').presence
    controller_action = "(#{payload.fetch(:controller)}##{payload.fetch(:action)})"

    [status, method_and_path, controller_action].compact.join(' ')
  end
end

class SemanticErrorSubscriber
  include SemanticLogger::Loggable

  def report(error, handled:, severity:, context:, source: nil)
    logger.send severity.to_s.sub(/ing$/, ''), { exception: error, handled:, context:, source: }
  end
end

Rails.error.subscribe(SemanticErrorSubscriber.new)
