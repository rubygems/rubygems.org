module UserTotpMethods
  extend ActiveSupport::Concern

  def totp_enabled?
    mfa_seed.present?
  end

  def totp_disabled?
    mfa_seed.blank?
  end

  def disable_totp!
    self.mfa_seed = ""

    if no_mfa_devices?
      self.mfa_level = "disabled"
      self.mfa_recovery_codes = []
    end

    save!(validate: false)
    Mailer.totp_disabled(id, Time.now.utc).deliver_later
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

    if mfa_device_count_one?
      self.mfa_level = level
      self.mfa_recovery_codes = Array.new(10).map { SecureRandom.hex(6) }
    end

    save!(validate: false)
    Mailer.totp_enabled(id, Time.now.utc).deliver_later
  end

  private

  def verify_totp(seed, otp)
    return false if seed.blank?

    totp = ROTP::TOTP.new(seed)
    return false unless totp.verify(otp, drift_behind: 30, drift_ahead: 30)

    save!(validate: false)
  end
end
