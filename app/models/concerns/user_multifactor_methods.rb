module UserMultifactorMethods
  extend ActiveSupport::Concern

  included do
    include UserTotpMethods
    include UserWebauthnMethods

    enum mfa_level: { disabled: 0, ui_only: 1, ui_and_api: 2, ui_and_gem_signin: 3 }, _prefix: :mfa

    validate :mfa_level_for_enabled_devices
  end

  def mfa_enabled?
    !mfa_disabled?
  end

  def mfa_device_count_one?
    (totp_disabled? && webauthn_credentials.count == 1) || (totp_enabled? && webauthn_disabled?)
  end

  def no_mfa_devices?
    totp_disabled? && webauthn_disabled?
  end

  def mfa_devices_present?
    !no_mfa_devices?
  end

  def mfa_gem_signin_authorized?(otp)
    return true unless strong_mfa_level?
    api_mfa_verified?(otp)
  end

  def mfa_recommended_not_yet_enabled?
    mfa_recommended? && mfa_disabled?
  end

  def mfa_recommended_weak_level_enabled?
    mfa_recommended? && mfa_ui_only?
  end

  def mfa_required_not_yet_enabled?
    mfa_required? && mfa_disabled?
  end

  def mfa_required_weak_level_enabled?
    mfa_required? && mfa_ui_only?
  end

  def ui_mfa_verified?(otp)
    otp = otp.to_s
    return true if verify_totp(totp_seed, otp)

    # Check if the given OTP is a actually a recovery code
    if mfa_hashed_recovery_codes.present?
      return false unless (hashed_code = mfa_hashed_recovery_codes.find { |code| BCrypt::Password.new(code) == otp })
      mfa_hashed_recovery_codes.delete(hashed_code)
      # Also delete the plaintext code for now, to prevent the case where a user uses all their codes
      # and then the backfill stops being idempotent
      mfa_recovery_codes.delete(otp)
    else
      # Not yet migrated to hashed recovery codes, so check the plaintext codes
      return false unless mfa_recovery_codes.delete(otp)
    end

    save!(validate: false)
  end

  def api_mfa_verified?(otp)
    return true if verify_webauthn_otp(otp)
    return true if ui_mfa_verified?(otp)
    false
  end

  private

  def strong_mfa_level?
    mfa_ui_and_gem_signin? || mfa_ui_and_api?
  end

  def mfa_recommended?
    return false if strong_mfa_level? || mfa_required?

    rubygems.mfa_recommended.any?
  end

  def mfa_required?
    return false if strong_mfa_level?

    rubygems.mfa_required.any?
  end

  def mfa_level_for_enabled_devices
    return if correct_mfa_level_set_conditions

    errors.add(:mfa_level, :invalid)
  end

  def correct_mfa_level_set_conditions
    (mfa_disabled? && no_mfa_devices?) || (mfa_enabled? && mfa_devices_present?)
  end

  class_methods do
    def without_mfa
      where(mfa_level: "disabled")
    end
  end
end
