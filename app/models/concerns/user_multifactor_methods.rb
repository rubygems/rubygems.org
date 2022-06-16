module UserMultifactorMethods
  extend ActiveSupport::Concern

  included do
    enum mfa_level: { disabled: 0, ui_only: 1, ui_and_api: 2, ui_and_gem_signin: 3 }, _prefix: :mfa

    def mfa_enabled?
      !mfa_disabled?
    end

    def disable_mfa!
      mfa_disabled!
      self.mfa_seed = ""
      self.mfa_recovery_codes = []
      save!(validate: false)
    end

    def verify_and_enable_mfa!(seed, level, otp, expiry)
      if expiry < Time.now.utc
        errors.add(:base, I18n.t("multifactor_auths.create.qrcode_expired"))
      elsif verify_digit_otp(seed, otp)
        enable_mfa!(seed, level)
      else
        errors.add(:base, I18n.t("multifactor_auths.incorrect_otp"))
      end
    end

    def enable_mfa!(seed, level)
      self.mfa_level = level
      self.mfa_seed = seed
      self.mfa_recovery_codes = Array.new(10).map { SecureRandom.hex(6) }
      save!(validate: false)
    end

    def mfa_gem_signin_authorized?(otp)
      return true unless strong_mfa_level?
      otp_verified?(otp)
    end

    def mfa_recommended_not_yet_enabled?
      mfa_recommended? && mfa_disabled?
    end

    def mfa_recommended_weak_level_enabled?
      mfa_recommended? && mfa_ui_only?
    end

    def otp_verified?(otp)
      otp = otp.to_s
      return true if verify_digit_otp(mfa_seed, otp)

      return false unless mfa_recovery_codes.include? otp
      mfa_recovery_codes.delete(otp)
      save!(validate: false)
    end

    private

    def strong_mfa_level?
      mfa_ui_and_gem_signin? || mfa_ui_and_api?
    end

    def mfa_recommended?
      return false if strong_mfa_level?

      rubygems.mfa_recommended.any?
    end

    def verify_digit_otp(seed, otp)
      totp = ROTP::TOTP.new(seed)
      return false unless totp.verify(otp, drift_behind: 30, drift_ahead: 30)

      save!(validate: false)
    end
  end

  class_methods do
    def without_mfa
      where(mfa_level: "disabled")
    end
  end
end
