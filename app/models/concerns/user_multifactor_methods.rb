module UserMultifactorMethods
  extend ActiveSupport::Concern

  included do
    include UserTotpMethods
    include UserWebauthnMethods

    enum mfa_level: { disabled: 0, ui_only: 1, ui_and_api: 2, ui_and_gem_signin: 3 }, _prefix: :mfa
  end

  def mfa_enabled?
    !mfa_disabled?
  end

  def mfa_gem_signin_authorized?(otp)
    return true unless strong_mfa_level? || webauthn_credentials.present?
    api_otp_verified?(otp)
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

  def ui_otp_verified?(otp)
    otp = otp.to_s
    return true if verify_totp(mfa_seed, otp)
    return false unless mfa_recovery_codes.include? otp
    mfa_recovery_codes.delete(otp)
    save!(validate: false)
  end

  def api_otp_verified?(otp)
    return true if verify_webauthn_otp(otp)
    return true if ui_otp_verified?(otp)
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

  class_methods do
    def without_mfa
      where(mfa_level: "disabled")
    end
  end
end
