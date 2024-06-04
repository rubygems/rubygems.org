module RequireMfa
  extend ActiveSupport::Concern

  def require_mfa(user = @user)
    return unless user&.mfa_enabled?
    initialize_mfa(user)
    prompt_mfa
  end

  # Call initialize_mfa once at the start of the MFA flow for a user (after login, after reset token verified).
  def initialize_mfa(user = @user)
    delete_mfa_session
    create_new_mfa_expiry
    session[:mfa_login_started_at] = Time.now.utc.to_s
    session[:mfa_user] = user.id
  end

  def prompt_mfa(alert: nil, status: :ok)
    @otp_verification_url = otp_verification_url
    setup_webauthn_authentication form_url: webauthn_verification_url
    flash.now.alert = alert if alert
    render template: "multifactor_auths/prompt", status:
  end

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

  def validate_webauthn(user = @user)
    return mfa_session_expired unless mfa_session_active?
    return mfa_not_enabled unless user&.mfa_enabled?
    return webauthn_failure unless webauthn_credential_verified?
    @mfa_label = user_webauthn_credential.nickname
    @mfa_method = "webauthn"
  end

  def mfa_session_expired
    invalidate_mfa_session(t("multifactor_auths.session_expired"))
  end

  def mfa_not_enabled
  end

  def incorrect_otp
    mfa_failure(t("multifactor_auths.incorrect_otp"))
  end

  def webauthn_failure
    invalidate_mfa_session(@webauthn_error)
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
