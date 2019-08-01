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
  protected_paths = [
    "/users",               # sign up
    "/session",             # sign in
    "/passwords",           # forgot password
    "/email_confirmations", # resend email confirmation
    "/session/mfa_create"   # mfa sign in
  ]

  mfa_forgot_password_regex = Regexp.new("\/users\/\\d+\/password\/mfa_edit")
  paths_regex = Regexp.union(protected_paths.map { |path| /\A#{Regexp.escape(path)}\z/ }.append(mfa_forgot_password_regex))

  # 100 req in 10 min
  # 200 req in 100 min
  # 300 req in 1000 min (0.7 days)
  # 400 req in 10000 min (6.9 days)
  (1..4).each do |level|
    throttle("clearance/ip/#{level}", limit: REQUEST_LIMIT * level, period: (LIMIT_PERIOD**level).seconds) do |req|
      req.ip if req.path =~ paths_regex && req.post?
    end
  end

  protected_api_paths = [
    "/api/v1/gems/yank",  # gem yank
    "/api/v1/gems"        # gem push
  ]
  add_owner_regex = Regexp.new("\/api\/v1\/gems\/\\w+\/owners")
  api_paths_regex = Regexp.union(protected_api_paths.map { |path| /\A#{Regexp.escape(path)}\z/ }.append(add_owner_regex))

  (1..4).each do |level|
    throttle("clearance/ip/api/#{level}", limit: REQUEST_LIMIT * level, period: (LIMIT_PERIOD**level).seconds) do |req|
      req.ip if req.path =~ api_paths_regex && (req.post? || req.delete?)
    end
  end

  # Throttle GET request for api_key by IP address
  throttle('api_key/ip', limit: REQUEST_LIMIT, period: LIMIT_PERIOD) do |req|
    req.ip if req.path =~ /\A#{Regexp.escape('/api/v1/api_key')}/ && req.get?
  end

  # Throttle PATCH and DELETE profile requests
  throttle("clearance/remember_token", limit: REQUEST_LIMIT, period: LIMIT_PERIOD) do |req|
    req.ip if req.path == "/profile" && (req.patch? || req.delete?)
  end

  # Throttle yank requests
  YANK_LIMIT = 10
  throttle("yank/ip", limit: YANK_LIMIT, period: LIMIT_PERIOD) do |req|
    req.ip if req.path == "/api/v1/gems/yank"
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
