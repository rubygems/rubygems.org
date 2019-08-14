class Rack::Attack
  REQUEST_LIMIT = 100
  REQUEST_LIMIT_PER_EMAIL = 10
  LIMIT_PERIOD = 10.minutes

  ### Prevent Brute-Force Login Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.

  ############################# rate limit per ip ############################
  # Throttle POST requests to /login by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"

  protected_ui_actions = [
    { controller: "sessions",            action: "create" },
    { controller: "sessions",            action: "mfa_create" },
    { controller: "users",               action: "create" },
    { controller: "passwords",           action: "mfa_edit" },
    { controller: "passwords",           action: "edit" },
    { controller: "passwords",           action: "create" },
    { controller: "profiles",            action: "update" },
    { controller: "profiles",            action: "destroy" },
    { controller: "email_confirmations", action: "create" }
  ]

  protected_api_actions = [
    { controller: "api/v1/deletions", action: "create" },
    { controller: "api/v1/rubygems",  action: "create" },
    { controller: "api/v1/owners",    action: "create" },
    { controller: "api/v1/owners",    action: "destroy" }
  ]

  def self.protected_route?(protected_actions, path, method)
    route_params = Rails.application.routes.recognize_path(path, method: method)
    protected_actions.any? { |hash| hash[:controller] == route_params[:controller] && hash[:action] == route_params[:action] }
  end

  # 100 req in 10 min
  # 200 req in 100 min
  # 300 req in 1000 min (0.7 days)
  # 400 req in 10000 min (6.9 days)
  (1..4).each do |level|
    throttle("clearance/ip/#{level}", limit: REQUEST_LIMIT * level, period: (LIMIT_PERIOD**level).seconds) do |req|
      req.ip if protected_route?(protected_ui_actions, req.path, req.request_method)
    end
  end

  (1..4).each do |level|
    throttle("api/ip/#{level}", limit: REQUEST_LIMIT * level, period: (LIMIT_PERIOD**level).seconds) do |req|
      req.ip if protected_route?(protected_api_actions, req.path, req.request_method)
    end
  end

  protected_api_key_action = [{ controller: "api/v1/api_keys", action: "show" }]

  # Throttle GET request for api_key by IP address
  throttle("api_key/ip", limit: REQUEST_LIMIT, period: LIMIT_PERIOD) do |req|
    req.ip if protected_route?(protected_api_key_action, req.path, req.request_method)
  end

  # Throttle yank requests
  YANK_LIMIT = 10
  protected_yank_action = [{ controller: "api/v1/deletions", action: "create" }]

  throttle("yank/ip", limit: YANK_LIMIT, period: LIMIT_PERIOD) do |req|
    req.ip if protected_route?(protected_yank_action, req.path, req.request_method)
  end

  ############################# rate limit per handle ############################
  # Throttle POST requests to /login by email param
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{req.email}"
  #
  # Note: This creates a problem where a malicious user could intentionally
  # throttle logins for another user and force their login requests to be
  # denied, but that's not very common and shouldn't happen to you. (Knock
  # on wood!)
  throttle("logins/handler", limit: REQUEST_LIMIT, period: LIMIT_PERIOD) do |req|
    if req.path == "/session" && req.post?
      # return the handler if present, nil otherwise
      req.params['session']['who'].presence if req.params['session']
    end
  end

  ############################# rate limit per email ############################
  throttle("password/email", limit: REQUEST_LIMIT_PER_EMAIL, period: LIMIT_PERIOD) do |req|
    if req.path == "/passwords" && req.post?
      # return the email if present, nil otherwise
      req.params['password']['email'].presence if req.params['password']
    end
  end

  throttle("email_confirmations/email", limit: REQUEST_LIMIT_PER_EMAIL, period: LIMIT_PERIOD) do |req|
    if req.path == "/email_confirmations" && req.post?
      # return the email if present, nil otherwise
      req.params['email_confirmation']['email'].presence if req.params['email_confirmation']
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # self.throttled_response = lambda do |_env|
  #   [503, {}, ['Service Temporarily Unavailable']]
  # end

  ### Logging ###

  ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
    request = payload[:request]

    data = {
      status: 429,
      request_id: request.env["action_dispatch.request_id"],
      client_ip: request.ip.to_s,
      method: request.env["REQUEST_METHOD"],
      path: request.env["REQUEST_PATH"],
      user_agent: request.user_agent,
      dest_host: request.host,
      throttle: {
        matched: request.env["rack.attack.matched"],
        discriminator: request.env["rack.attack.match_discriminator"],
        match_data: request.env["rack.attack.match_data"]
      }
    }
    event = LogStash::Event.new(data)
    event['message'] = "[#{data[:status]}] #{data[:method]} #{data[:path]}"
    Rails.logger.info event.to_json
  end
end
