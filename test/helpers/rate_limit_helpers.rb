module RateLimitHelpers
  def exceeding_limit
    (Rack::Attack::REQUEST_LIMIT * 1.25).to_i
  end

  def exceeding_email_limit
    (Rack::Attack::REQUEST_LIMIT_PER_EMAIL * 1.25).to_i
  end

  def exceeding_exp_base_limit
    (Rack::Attack::EXP_BASE_REQUEST_LIMIT * 1.25).to_i
  end

  def under_limit
    (Rack::Attack::REQUEST_LIMIT * 0.5).to_i
  end

  def under_email_limit
    (Rack::Attack::REQUEST_LIMIT_PER_EMAIL * 0.5).to_i
  end

  def limit_period
    Rack::Attack::LIMIT_PERIOD
  end

  def push_limit_period
    Rack::Attack::PUSH_LIMIT_PERIOD
  end

  def exp_base_limit_period
    Rack::Attack::EXP_BASE_LIMIT_PERIOD
  end

  def exceed_limit_for(scope)
    update_limit_for("#{scope}:#{@ip_address}", exceeding_limit)
  end

  def exceed_email_limit_for(scope)
    update_limit_for("#{scope}:#{@user.email}", exceeding_email_limit)
  end

  def exceed_handle_limit_for(scope, user)
    update_limit_for("#{scope}:#{user.handle}", exceeding_email_limit)
  end

  def exceed_push_limit_for(scope)
    exceeding_push_limit = (Rack::Attack::PUSH_LIMIT * 1.25).to_i
    update_limit_for("#{scope}:#{@ip_address}", exceeding_push_limit, push_limit_period)
  end

  def exceed_exp_base_limit_for(scope)
    update_limit_for("#{scope}:#{@ip_address}", exceeding_exp_base_limit, exp_base_limit_period)
  end

  def stay_under_limit_for(scope)
    update_limit_for("#{scope}:#{@ip_address}", under_limit)
  end

  def stay_under_email_limit_for(scope)
    update_limit_for("#{scope}:#{@user.email}", under_email_limit)
  end

  def stay_under_ownership_request_limit_for(scope)
    update_limit_for("#{scope}:#{@user.email}", under_email_limit, Rack::Attack::REQUEST_LIMIT_PERIOD)
  end

  def stay_under_push_limit_for(scope)
    under_push_limit = (Rack::Attack::PUSH_LIMIT * 0.5).to_i
    update_limit_for("#{scope}:#{@user.email}", under_push_limit)
  end

  def stay_under_exponential_limit(scope)
    Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
      under_backoff_limit = (Rack::Attack::EXP_BASE_REQUEST_LIMIT * level) - 1
      throttle_level_key = "#{scope}/#{level}:#{@ip_address}"
      under_backoff_limit.times { Rack::Attack.cache.count(throttle_level_key, exp_base_limit_period**level) }
    end
  end

  def update_limit_for(key, limit, period = limit_period)
    limit.times { Rack::Attack.cache.count(key, period) }
  end

  def exceed_exponential_limit_for(scope, level)
    expo_exceeding_limit = exceeding_exp_base_limit * level
    expo_limit_period = exp_base_limit_period**level
    expo_exceeding_limit.times { Rack::Attack.cache.count("#{scope}:#{@ip_address}", expo_limit_period) }
  end

  def exceed_exponential_user_limit_for(scope, id, level)
    expo_exceeding_limit = exceeding_exp_base_limit * level
    expo_limit_period = exp_base_limit_period**level
    expo_exceeding_limit.times { Rack::Attack.cache.count("#{scope}:#{id}", expo_limit_period) }
  end

  def exceed_exponential_api_key_limit_for(scope, user_display_id, level)
    expo_exceeding_limit = exceeding_exp_base_limit * level
    expo_limit_period = exp_base_limit_period**level
    expo_exceeding_limit.times { Rack::Attack.cache.count("#{scope}:#{user_display_id}", expo_limit_period) }
  end

  def encode(username, password)
    ActionController::HttpAuthentication::Basic
      .encode_credentials(username, password)
  end

  def expected_retry_after(level)
    now = Time.now.to_i
    period = Rack::Attack::EXP_BASE_LIMIT_PERIOD**level
    (period - (now % period)).to_s
  end

  def exceed_ownership_request_limit_for(scope)
    update_limit_for("#{scope}:#{@user.email}", exceeding_email_limit, Rack::Attack::REQUEST_LIMIT_PERIOD)
  end

  def assert_throttle_at(level)
    assert_response :too_many_requests
    assert_equal expected_retry_after(level), @response.headers["Retry-After"]
    assert @response.headers["Retry-After"].to_i < @mfa_max_period[level]
  end
end
