class Rack::Attack
  DEFAULT_LIMIT = 100
  DEFAULT_PERIOD = 10.minutes
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
    "/users",              # sign up
    "/session",            # sign in
    "/passwords",          # forgot password
    "/email_confirmations" # resend email confirmation
  ]
  paths_regex = Regexp.union(protected_paths.map { |path| /\A#{Regexp.escape(path)}\z/ })

  throttle('clearance/ip', limit: DEFAULT_LIMIT, period: DEFAULT_PERIOD) do |req|
    req.ip if req.path =~ paths_regex && req.post?
  end

  # Throttle GET request for api_key by IP address
  throttle('api_key/ip', limit: DEFAULT_LIMIT, period: DEFAULT_PERIOD) do |req|
    req.ip if req.path =~ /\A#{Regexp.escape('/api/v1/api_key')}/ && req.get?
  end

  # Throttle PATCH and DELETE profile requests
  throttle("clearance/remember_token", limit: DEFAULT_LIMIT, period: DEFAULT_PERIOD) do |req|
    req.ip if req.path == "/profile" && (req.patch? || req.delete?)
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
  throttle("logins/handler", limit: DEFAULT_LIMIT, period: DEFAULT_PERIOD) do |req|
    if req.path == "/session" && req.post?
      # return the handler if present, nil otherwise
      req.params['session']['who'].presence if req.params['session']
    end
  end

  ############################# rate limit per email ############################
  EMAIL_LIMIT = 10

  throttle("password/email", limit: EMAIL_LIMIT, period: DEFAULT_PERIOD) do |req|
    if req.path == "/passwords" && req.post?
      # return the email if present, nil otherwise
      req.params['password']['email'].presence if req.params['password']
    end
  end

  throttle("email_confirmations/email", limit: EMAIL_LIMIT, period: DEFAULT_PERIOD) do |req|
    if req.path == "/email_confirmations" && req.post?
      # return the email if present, nil otherwise
      req.params['email_confirmation']['email'].presence if req.params['email_confirmation']
    end
  end

  ############################ gem push rate limits ##############################
  GEM_PUSH_LIMIT = 20
  KEY_LIMIT_PERIOD = 1.hour

  throttle("gem_push/api_key", limit: GEM_PUSH_LIMIT, period: KEY_LIMIT_PERIOD) do |req|
    (req.env["HTTP_AUTHORIZATION"] || req.params["api_key"]) if req.path == "/api/v1/gems" && req.post?
  end

  throttle("gem_push/ip", limit: GEM_PUSH_LIMIT, period: DEFAULT_PERIOD) do |req|
    req.ip if req.path == "/api/v1/gems" && req.post?
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

  ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _request_id, payload|
    if payload.env['rack.attack.match_type'] == :throttle
      data = {
        status: 'throttled',
        ip: payload.ip.to_s,
        method: payload.env["REQUEST_METHOD"],
        path: payload.env["REQUEST_PATH"],
        matched: payload.env["rack.attack.matched"],
        discriminator: payload.env["rack.attack.match_discriminator"],
        match_data: payload.env["rack.attack.match_data"]
      }
      Rails.logger.info data
    end
  end
end
