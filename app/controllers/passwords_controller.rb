class PasswordsController < ApplicationController
  include MfaExpiryMethods
  include RequireMfa
  include WebauthnVerifiable

  before_action :ensure_email_present, only: %i[create]

  before_action :no_referrer, only: %i[edit otp_edit webauthn_edit]
  before_action :validate_confirmation_token, only: %i[edit otp_edit webauthn_edit]
  before_action :require_mfa, only: %i[edit]
  before_action :validate_otp, only: %i[otp_edit]
  before_action :validate_webauthn, only: %i[webauthn_edit]
  before_action :password_reset_session_verified, only: %i[edit otp_edit webauthn_edit]
  after_action :delete_mfa_expiry_session, only: %i[otp_edit webauthn_edit]

  before_action :validate_password_reset_session, only: :update

  def new
  end

  def edit
    render :edit
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
      delete_password_reset_session
      flash[:notice] = t(".success")
      redirect_to signed_in? ? dashboard_path : sign_in_path
    else
      flash.now[:alert] = t(".failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def otp_edit
    render :edit
  end

  def webauthn_edit
    render :edit
  end

  private

  def ensure_email_present
    @email = params.dig(:password, :email)
    return if @email.present?

    flash.now[:alert] = t(".failure_on_missing_email")
    render template: "passwords/new", status: :unprocessable_entity
  end

  def validate_confirmation_token
    confirmation_token = params.permit(:token).fetch(:token, "").to_s
    return login_failure(t("passwords.edit.token_failure")) if confirmation_token.blank?
    @user = User.find_by(confirmation_token:)
    return login_failure(t("passwords.edit.token_failure")) unless @user&.valid_confirmation_token?
    sign_out if signed_in? && @user != current_user
  end

  # The order of these methods intends to leave the session fully reset if we
  # fail to invalidate the token for some reason, since this would indicate
  # something is wrong with the user, necessitating help from an admin.
  def password_reset_session_verified
    reset_session
    @user.update!(confirmation_token: nil)
    session[:password_reset_verified_user] = @user.id
    session[:password_reset_verified] = Gemcutter::PASSWORD_VERIFICATION_EXPIRY.from_now
  end

  def validate_password_reset_session
    return login_failure(t("passwords.edit.token_failure")) if session[:password_reset_verified].nil?
    return login_failure(t("verification_expired")) if Time.current.after?(session[:password_reset_verified])
    @user = User.find_by(id: session[:password_reset_verified_user])
    login_failure(t("verification_expired")) unless @user
  end

  def delete_password_reset_session
    delete_mfa_session
    session.delete(:password_reset_verified_user)
    session.delete(:password_reset_verified)
  end

  def reset_params
    params.permit(password_reset: %i[password reset_api_key reset_api_keys]).require(:password_reset)
  end

  def mfa_failure(message)
    prompt_mfa(alert: message, status: :unauthorized)
  end

  def login_failure(alert)
    reset_session
    redirect_to sign_in_path, alert:
  end

  def otp_verification_url
    otp_edit_password_url(token: @user.confirmation_token)
  end

  def webauthn_verification_url
    webauthn_edit_password_url(token: @user.confirmation_token)
  end
end
