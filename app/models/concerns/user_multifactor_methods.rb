module UserMultifactorMethods
  extend ActiveSupport::Concern

  included do
    include UserTotpMethods
    include UserWebauthnMethods

    attr_accessor :new_mfa_recovery_codes

    enum :mfa_level, { disabled: 0, ui_only: 1, ui_and_api: 2, ui_and_gem_signin: 3 }, prefix: :mfa

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

    return false unless verify_mfa_recovery_code(otp)

    save!(validate: false)
  end

  def api_mfa_verified?(otp)
    return true if verify_webauthn_otp(otp)
    return true if ui_mfa_verified?(otp)
    false
  end

  def mfa_method_added(default_level)
    return unless mfa_device_count_one?

    self.mfa_level = default_level
    self.new_mfa_recovery_codes = Array.new(10).map { SecureRandom.hex(6) }
    self.mfa_hashed_recovery_codes = new_mfa_recovery_codes.map { |code| BCrypt::Password.create(code) }
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

  def verify_mfa_recovery_code(otp)
    hashed_code = mfa_hashed_recovery_codes.find { |code| BCrypt::Password.new(code) == otp }
    return unless hashed_code
    mfa_hashed_recovery_codes.delete(hashed_code)
  end

  class_methods do
    def without_mfa
      where(mfa_level: "disabled")
    end
  end
end
