module RequireMfa
  extend ActiveSupport::Concern

  def otp_param
    params.permit(:otp).fetch(:otp, "")
  end

  def validate_otp(user = @user)
    return mfa_session_expired unless mfa_session_active?
    return mfa_not_enabled unless user&.mfa_enabled?
    return incorrect_otp unless user.ui_mfa_verified?(otp_param)
    @mfa_label = "OTP"
    @mfa_method = "otp"
  end

  def mfa_session_expired
    invalidate_mfa_session(t("multifactor_auths.session_expired"))
  end

  def mfa_not_enabled
  end

  def incorrect_otp
    mfa_failure(t("multifactor_auths.incorrect_otp"))
  end

  def invalidate_mfa_session(message)
    delete_mfa_session
    mfa_failure(message)
  end

  def delete_mfa_session
    delete_mfa_expiry_session
    session.delete(:webauthn_authentication)
    session.delete(:mfa_login_started_at)
    session.delete(:mfa_user)
    session.delete(:level)
  end
end
