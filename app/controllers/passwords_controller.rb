class PasswordsController < ApplicationController
  include MfaExpiryMethods
  include RequireMfa
  include WebauthnVerifiable
  include SessionVerifiable

  before_action :ensure_email_present, only: %i[create]

  before_action :validate_confirmation_token, only: %i[edit otp_edit webauthn_edit]
  before_action :session_expired_failure, only: %i[otp_edit webauthn_edit], unless: :mfa_session_active?
  before_action :webauthn_failure, only: %i[webauthn_edit], unless: :webauthn_credential_verified?
  before_action :validate_otp, only: %i[otp_edit]
  after_action :delete_mfa_expiry_session, only: %i[otp_edit webauthn_edit]

  verify_session_before only: %i[update]

  def new
  end

  def edit
    if @user.mfa_enabled?
      @otp_verification_url = otp_verification_url
      setup_webauthn_authentication(form_url: webauthn_verification_url)

      create_new_mfa_expiry

      render template: "multifactor_auths/prompt"
    else
      # When user doesn't have mfa, a valid token is a full "magic link" sign in.
      verified_sign_in
      render :edit
    end
  end

  def create
    user = User.find_by_normalized_email(@email)

    if user
      user.forgot_password!
      ::PasswordMailer.change_password(user).deliver_later
    end

    render :create, status: :accepted
  end

  def update
    if current_user.update_password reset_params[:password]
      current_user.reset_api_key! if reset_params[:reset_api_key] == "true" # singular
      current_user.api_keys.expire_all! if reset_params[:reset_api_keys] == "true" # plural
      redirect_to dashboard_path
      session[:password_reset_token] = nil
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def otp_edit
    verified_sign_in
    render :edit
  end

  def webauthn_edit
    verified_sign_in
    render :edit
  end

  private

  def verified_sign_in
    sign_in @user
    session_verified
    @user.update!(confirmation_token: nil)
    StatsD.increment "login.success"
  end

  def reset_params
    params.fetch(:password_reset, {}).permit(:password, :reset_api_key, :reset_api_keys)
  end

  def ensure_email_present
    @email = params.dig(:password, :email)
    return if @email.present?

    flash.now[:alert] = t(".failure_on_missing_email")
    render template: "passwords/new", status: :unprocessable_entity
  end

  def validate_confirmation_token
    @user = User.find_by(confirmation_token: params[:token].to_s)
    redirect_to root_path, alert: t("passwords.edit.token_failure") unless @user&.valid_confirmation_token?
  end

  def session_expired_failure = login_failure(t("multifactor_auths.session_expired"))
  def webauthn_failure = login_failure(@webauthn_error)

  def login_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/prompt", status: :unauthorized
  end

  def mfa_failure(message)
    login_failure(message)
  end

  def redirect_to_verify
    session[:redirect_uri] = verify_session_redirect_path
    redirect_to verify_session_path, alert: t("verification_expired")
  end

  def otp_verification_url
    otp_edit_password_url(token: @user.confirmation_token)
  end

  def webauthn_verification_url
    webauthn_edit_password_url(token: @user.confirmation_token)
  end
end
