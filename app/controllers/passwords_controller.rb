class PasswordsController < ApplicationController
  include MfaExpiryMethods
  include WebauthnVerifiable

  before_action :ensure_email_present, only: %i[create]
  before_action :clear_password_reset_session, only: %i[create edit]

  before_action :no_referrer, only: %i[edit]
  before_action :validate_confirmation_token, only: %i[edit otp_edit webauthn_edit]
  before_action :session_expired_failure, only: %i[otp_edit webauthn_edit], unless: :session_active?
  before_action :webauthn_failure, only: %i[webauthn_edit], unless: :webauthn_credential_verified?
  before_action :otp_failure, only: %i[otp_edit], unless: :otp_edit_conditions_met?
  after_action :delete_mfa_expiry_session, only: %i[otp_edit webauthn_edit]

  before_action :validate_password_reset_session, only: %i[update]

  def new
  end

  def edit
    if @user.mfa_enabled?
      @otp_verification_url = otp_edit_user_password_url(@user, token: @user.confirmation_token)
      setup_webauthn_authentication(form_url: webauthn_edit_user_password_url(token: @user.confirmation_token))

      create_new_mfa_expiry

      render template: "multifactor_auths/prompt"
    else
      password_reset_verified
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
    if @user.update_password reset_params[:password]
      @user.reset_api_key! if reset_params[:reset_api_key] == "true" # singular
      @user.api_keys.expire_all! if reset_params[:reset_api_keys] == "true" # plural
      clear_password_reset_session
      sign_in @user
      redirect_to dashboard_path
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def otp_edit
    password_reset_verified
    render :edit
  end

  def webauthn_edit
    password_reset_verified
    render :edit
  end

  private

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
    confirmation_token = params[:token] || session[:password_reset_token]
    @user = User.find_by(id: params[:user_id], confirmation_token:)
    return token_failure(t("passwords.edit.token_failure")) unless @user&.valid_confirmation_token?
    session[:password_reset_token] = confirmation_token
  end

  def otp_edit_conditions_met? = @user.mfa_enabled? && @user.ui_mfa_verified?(params[:otp]) && session_active?

  def session_expired_failure = mfa_failure(t("multifactor_auths.session_expired"))
  def webauthn_failure = mfa_failure(@webauthn_error)
  def otp_failure = mfa_failure(t("multifactor_auths.incorrect_otp"))

  def mfa_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/prompt", status: :unauthorized
  end

  def token_failure(message)
    clear_password_reset_session
    redirect_to root_path, alert: message
  end

  # password reset session is a short lived session that can only perform password reset.
  def password_reset_verified
    clear_password_reset_session
    session[:password_reset_user] = @user.id
    session[:password_reset_verification] = Gemcutter::PASSWORD_VERIFICATION_EXPIRY.from_now
  end

  def validate_password_reset_session
    return token_failure(t("passwords.edit.session_expired")) unless password_reset_session_active?
    @user = User.find(session[:password_reset_user])
  end

  def password_reset_session_active?
    session[:password_reset_verification] && session[:password_reset_verification] > Time.current
  end

  def clear_password_reset_session
    session.delete(:password_reset_token)
    session.delete(:password_reset_user)
    session.delete(:password_reset_verification)
  end

  # Avoid leaking token in referrer header (OWASP: forgot password)
  def no_referrer
    headers["Referrer-Policy"] = "no-referrer"
  end
end
