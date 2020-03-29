module RackAttackReset
  def self.gem_push_backoff(remote_ip)
    Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
      Rack::Attack.cache.reset_count("#{Rack::Attack::PUSH_EXP_THROTTLE_KEY}/#{level}:#{remote_ip}", Rack::Attack::EXP_BASE_LIMIT_PERIOD**level)
    end
  end
end
