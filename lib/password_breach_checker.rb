# frozen_string_literal: true

class PasswordBreachChecker
  def initialize(password)
    @password = Pwned::Password.new(password.to_s, request_options: { read_timeout: 3, open_timeout: 3 })
  end

  def breached?
    return @breached if defined?(@breached)
    @breached = @password.pwned?
  rescue Pwned::TimeoutError, Pwned::Error => e
    Rails.logger.warn "HIBP check failed: #{e.class}"
    StatsD.increment "login.hibp_check.error"
    @breached = false
  end

  def inspect
    "#<PasswordBreachChecker:#{object_id} password=[FILTERED]>"
  end
end
