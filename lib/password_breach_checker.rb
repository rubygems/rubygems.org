class PasswordBreachChecker
  def initialize(password)
    @password = Pwned::Password.new(password.to_s)
  end

  def breached?
    @password.pwned?
  rescue Pwned::TimeoutError, Pwned::Error => e
    Rails.logger.warn "HIBP check failed: #{e.class}"
    StatsD.increment "login.hibp_check.error"
    false
  end

  def inspect
    "#<PasswordBreachChecker:#{object_id} password=[FILTERED] breached=#{breached?}>"
  end
end
