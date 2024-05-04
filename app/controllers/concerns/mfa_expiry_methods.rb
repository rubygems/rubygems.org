# This expiry is meant to prevent people from sitting on the MFA screen for
# unlimited time, which presents a security issue.
#
# When a user renders the page prompting for MFA, they will have 15 minutes to
# enter their OTP or WebAuthN before the session expires, which would then
# require them to log in again (or start a new password reset).
#
# After successfully completing MFA, the user will have an additional 15 minutes
# to complete the process before mfa session is cleared, calling `invalidate_session`.
#
# When a user initiates an authenticated process that requires MFA:
# 1. Call `initialize_mfa` only once to before the require_mfa call.
# 2. Call `require_mfa` in a before_action that protects all actions
#    that require MFA (not just rendering the form but also submitting it).
# 3. Implement invalidate_session(reason) in the controller to clear any session state
#    and redirect the user to the beginning of the process.
module MfaExpiryMethods
  extend ActiveSupport::Concern

  # Call initialize_mfa once at the start of the MFA flow for a user (after login, after reset token verified).
  def initialize_mfa(user = @user)
    delete_mfa_session
    session[:mfa_login_started_at] = Time.now.utc.to_s
    session[:mfa_expiry] = 15.minutes.from_now.to_s
    session[:mfa_user] = user.id
  end

  # Call require_mfa in a before_action to protect all actions that require MFA.
  def require_mfa(user = @user)
    return unless user.mfa_enabled?
    return invalidate_mfa_session if invalid_mfa_session?(user)
    mfa_verified?(user) || validate_webauthn || validate_otp(user) || prompt_mfa
  end

  # Implement invalidate_session in the controller to clear any session state and redirect the user to the beginning of the process.
  def invalidate_session(reason)
    raise NotImplementedError, "invalidate_session must be implemented in the controller"
  end

  # Call delete_mfa_session if the user invalidates or completes the process requiring MFA.
  def delete_mfa_session
    session.delete(:mfa_user)
    session.delete(:mfa_expiry)
    session.delete(:mfa_verified)
    session.delete(:mfa_login_started_at)
    session.delete(:webauthn_authentication)
  end

  private

  def invalidate_mfa_session
    invalidate_session(t("multifactor_auths.session_expired"))
    delete_mfa_session
    true
  end

  def valid_mfa_session?(user = nil)
    return false if session[:mfa_expiry].blank? || Time.current.after?(session[:mfa_expiry])
    return true if session[:mfa_user].blank? # TODO: remove me next! Allows existing sessions to finish after first deploy.
    user.nil? || session[:mfa_user] == user.id
  end

  def invalid_mfa_session?(user = nil) = !valid_mfa_session?(user)

  def mfa_verified?(user)
    valid_mfa_session?(user) && session[:mfa_verified]
  end

  def validate_webauthn
    return unless webauthn_credential_present?
    return mfa_verified if webauthn_credential_verified?
    mfa_failure @webauthn_error
  end

  def validate_otp(user)
    otp_param = params.permit(:otp).fetch(:otp, nil)
    return if otp_param.blank?
    return mfa_verified if user.ui_mfa_verified?(otp_param)
    mfa_failure t("multifactor_auths.incorrect_otp")
  end

  def mfa_failure(alert)
    prompt_mfa alert:, status: :unauthorized
  end

  def otp_verification_url
    url_for
  end

  def webauthn_verification_url
    url_for
  end

  def prompt_mfa(alert: nil, status: :ok)
    @otp_verification_url = otp_verification_url
    setup_webauthn_authentication form_url: webauthn_verification_url
    flash.now.alert = alert if alert
    render template: "multifactor_auths/prompt", status:
  end

  def mfa_verified
    session[:mfa_expiry] = 15.minutes.from_now.to_s
    session[:mfa_verified] = true
  end

  def record_mfa_login_duration(mfa_type:)
    started_at = Time.zone.parse(session[:mfa_login_started_at]).utc
    duration = Time.now.utc - started_at

    StatsD.distribution("login.mfa.#{mfa_type}.duration", duration)
  end

  included do
    # Legacy version doesn't check user
    def create_new_mfa_expiry
      session[:mfa_expires_at] = 15.minutes.from_now.to_s
    end

    def delete_mfa_expiry_session
      session.delete(:mfa_expires_at)
    end

    # Clear the session key when mfa has expired. This makes mfa_session_active? before_action guards simpler to write.
    def mfa_session_active?
      return false if session[:mfa_expires_at].nil?
      delete_mfa_expiry_session if Time.current > session[:mfa_expires_at]
      session[:mfa_expires_at].present?
    end
  end
end
