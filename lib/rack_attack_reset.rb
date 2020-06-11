module RackAttackReset
  class << self
    def gem_push_backoff(remote_ip)
      Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
        keys(level, remote_ip).each { |key| Rack::Attack.cache.store.delete(key) }
      end
    end

    private

    def keys(level, remote_ip)
      period            = Rack::Attack::EXP_BASE_LIMIT_PERIOD**level
      time_counter      = (Time.now.to_i / period).to_i
      # counter may have incremented by 1 since the key was set, best to reset prev counter as well.
      # pre time counter/window key is applicable for +1 second after the counter has changed
      # see: https://github.com/kickstarter/rack-attack/pull/85
      prev_time_counter = time_counter - 1
      prefix            = Rack::Attack.cache.prefix

      ["#{prefix}:#{time_counter}:#{Rack::Attack::PUSH_EXP_THROTTLE_KEY}/#{level}:#{remote_ip}",
       "#{prefix}:#{prev_time_counter}:#{Rack::Attack::PUSH_EXP_THROTTLE_KEY}/#{level}:#{remote_ip}"]
    end
  end
end
