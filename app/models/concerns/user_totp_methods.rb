module UserTotpMethods
  extend ActiveSupport::Concern

  def totp_enabled?
    mfa_seed.present?
  end

  def totp_disabled?
    mfa_seed.blank?
  end

  def disable_totp!
    mfa_disabled!
    self.mfa_seed = ""
    self.mfa_recovery_codes = []
    save!(validate: false)
    Mailer.mfa_disabled(id, Time.now.utc).deliver_later
  end

  def verify_and_enable_totp!(seed, level, otp, expiry)
    if expiry < Time.now.utc
      errors.add(:base, I18n.t("multifactor_auths.create.qrcode_expired"))
    elsif verify_totp(seed, otp)
      enable_totp!(seed, level)
    else
      errors.add(:base, I18n.t("multifactor_auths.incorrect_otp"))
    end
  end

  def enable_totp!(seed, level)
    self.mfa_seed = seed

    if webauthn_disabled?
      self.mfa_level = level
    end

    self.mfa_recovery_codes = Array.new(10).map { SecureRandom.hex(6) }
    save!(validate: false)
    Mailer.mfa_enabled(id, Time.now.utc).deliver_later
  end

  private

  def verify_totp(seed, otp)
    return false if seed.blank?

    totp = ROTP::TOTP.new(seed)
    return false unless totp.verify(otp, drift_behind: 30, drift_ahead: 30)

    save!(validate: false)
  end
end
