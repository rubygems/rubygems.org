module RateLimitHelper
  def exceeding_limit
    (Rack::Attack::DEFAULT_LIMIT * 1.25).to_i
  end

  def exceeding_email_limit
    (Rack::Attack::EMAIL_LIMIT * 1.25).to_i
  end

  def exceeding_push_limit
    (Rack::Attack::GEM_PUSH_LIMIT * 1.25).to_i
  end

  def under_limit
    (Rack::Attack::DEFAULT_LIMIT * 0.5).to_i
  end

  def under_email_limit
    (Rack::Attack::EMAIL_LIMIT * 0.5).to_i
  end

  def limit_period
    Rack::Attack::DEFAULT_PERIOD
  end

  def key_limit_period
    Rack::Attack::KEY_LIMIT_PERIOD
  end

  def update_limit_for(key, limit)
    limit.times { Rack::Attack.cache.count(key, limit_period) }
  end

  def exceed_limit_for(scope)
    update_limit_for("#{scope}:#{@ip_address}", exceeding_limit)
  end

  def exceed_email_limit_for(scope)
    update_limit_for("#{scope}:#{@user.email}", exceeding_email_limit)
  end

  def exceed_ip_push_limit
    update_limit_for("gem_push/ip:#{@ip_address}", exceeding_push_limit)
  end

  def exceed_key_push_limit
    exceeding_push_limit.times { Rack::Attack.cache.count("gem_push/api_key:#{@user.api_key}", key_limit_period) }
  end

  def stay_under_limit_for(scope)
    update_limit_for("#{scope}:#{@ip_address}", under_limit)
  end

  def stay_under_email_limit_for(scope)
    update_limit_for("#{scope}:#{@user.email}", under_email_limit)
  end

  def encode(username, password)
    ActionController::HttpAuthentication::Basic
      .encode_credentials(username, password)
  end
end
