class PasswordsController < Clearance::PasswordsController
  include MfaExpiryMethods
  include WebauthnVerifiable
  include SessionVerifiable

  before_action :validate_confirmation_token, only: %i[edit otp_edit webauthn_edit]
  after_action :delete_mfa_expiry_session, only: %i[otp_edit webauthn_edit]

  # By default, clearance expects the token to be submitted with the password update.
  # We already invalidated the token when the user became verified by token(+mfa).
  skip_before_action :ensure_existing_user, only: %i[update]
  # Instead of the token, we now require the user to have been verified recently.
  verify_session_before only: %i[update]

  def edit
    if @user.mfa_enabled?
      @otp_verification_url = otp_edit_user_password_url(@user, token: @user.confirmation_token)
      setup_webauthn_authentication(form_url: webauthn_edit_user_password_url(token: @user.confirmation_token))

      create_new_mfa_expiry

      render template: "multifactor_auths/prompt"
    else
      # When user doesn't have mfa, a valid token is a full "magic link" sign in.
      verified_sign_in
      render template: "passwords/edit"
    end
  end

  def update
    if current_user.update_password password_from_password_reset_params
      current_user.reset_api_key! if reset_params[:reset_api_key] == "true"
      current_user.api_keys.expire_all! if reset_params[:reset_api_keys] == "true"
      redirect_to url_after_update
      session[:password_reset_token] = nil
    else
      flash_failure_after_update
      render template: "passwords/edit"
    end
  end

  def otp_edit
    if otp_edit_conditions_met?
      # When the user identified by the email token submits adequate totp, they are logged in
      verified_sign_in
      render template: "passwords/edit"
    elsif !session_active?
      login_failure(t("multifactor_auths.session_expired"))
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  def webauthn_edit
    unless session_active?
      login_failure(t("multifactor_auths.session_expired"))
      return
    end

    return login_failure(@webauthn_error) unless webauthn_credential_verified?

    # When the user identified by the email token submits verified webauthn, they are logged in
    verified_sign_in
    render template: "passwords/edit"
  end

  private

  def verified_sign_in
    sign_in @user
    session_verified
    @user.update!(confirmation_token: nil)
    StatsD.increment "login.success"
  end

  def url_after_update
    dashboard_path
  end

  def reset_params
    params.fetch(:password_reset, {}).permit(:reset_api_key, :reset_api_keys)
  end

  def validate_confirmation_token
    @user = find_user_for_edit
    redirect_to root_path, alert: t("failure_when_forbidden") unless @user&.valid_confirmation_token?
  end

  def deliver_email(user)
    ::PasswordMailer.change_password(user).deliver_later
  end

  def otp_edit_conditions_met?
    @user.mfa_enabled? && @user.ui_mfa_verified?(params[:otp]) && session_active?
  end

  def login_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/prompt", status: :unauthorized
  end

  def redirect_to_verify
    session[:redirect_uri] = verify_session_redirect_path
    redirect_to verify_session_path, alert: t("verification_expired")
  end
end
