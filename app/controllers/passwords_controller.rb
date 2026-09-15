# frozen_string_literal: true

class PasswordsController < ApplicationController
  include MfaExpiryMethods
  include RequireMfa
  include WebauthnVerifiable

  before_action :ensure_email_present, only: %i[create]

  prepend_before_action :protect_password_reset_response, only: %i[edit reset otp_edit webauthn_edit update]
  before_action :begin_password_reset, only: :edit
  before_action :load_password_reset, only: %i[reset otp_edit webauthn_edit update]
  before_action :validate_otp, only: %i[otp_edit]
  before_action :validate_webauthn, only: %i[webauthn_edit]
  after_action :delete_mfa_expiry_session, only: %i[otp_edit webauthn_edit]

  before_action :validate_password_reset_verification, only: :update

  def new
    render :new
  end

  def edit
    render_password_reset
  end

  def reset
    render_password_reset
  end

  def create
    user = User.find_by_normalized_email(@email)

    if user
      user.invalidate_password_reset!
      ::PasswordMailer.change_password(user).deliver_later
    end

    render :create, status: :accepted
  end

  def update
    case @user.update_password_with_token(reset_params[:password], token: session[:password_reset_token])
    when :updated
      @user.reset_api_key! if reset_params[:reset_api_key] == "true" # singular
      @user.api_keys.expire_all! if reset_params[:reset_api_keys] == "true" # plural
      StatsD.increment "login.password_compromised.reset_completed" if session[:password_reset_reason] == "compromised"
      delete_password_reset_session
      flash[:notice] = t(".success")
      redirect_to signed_in? ? dashboard_path : sign_in_path
    when :invalid_password
      set_compromised_flag
      flash.now[:alert] = t(".failure")
      render :edit, status: :unprocessable_content
    else
      login_failure(t("passwords.edit.token_failure"))
    end
  end

  def otp_edit
    complete_password_reset_verification
  end

  def webauthn_edit
    complete_password_reset_verification
  end

  private

  def render_password_reset
    return require_mfa if password_reset_requires_mfa?

    mark_password_reset_verified unless password_reset_verification_active?
    set_compromised_flag
    render :edit
  end

  def protect_password_reset_response
    disable_cache
    no_referrer
    response.headers["Cache-Control"] = "private, no-store"
    response.headers["Surrogate-Control"] = "no-store"
  end

  def set_compromised_flag
    @compromised = session[:password_reset_reason] == "compromised"
  end

  def ensure_email_present
    @email = params.dig(:password, :email)
    return if @email.present?

    flash.now[:alert] = t(".failure_on_missing_email")
    render template: "passwords/new", status: :unprocessable_content
  end

  def begin_password_reset
    token = params.permit(:token).fetch(:token, "").to_s
    @user = User.find_by_password_reset_token(token)
    return login_failure(t("passwords.edit.token_failure")) unless @user&.valid_password_reset_token?(token)

    compromised = @user.valid_compromised_password_reset_reason?(params[:reason], token:)
    sign_out if signed_in? && @user != current_user
    reset_session
    session[:password_reset_user] = @user.id
    session[:password_reset_token] = token
    session[:password_reset_reason] = "compromised" if compromised
  end

  def load_password_reset
    token = session[:password_reset_token]
    @user = User.find_by_password_reset_token(token)
    return if @user && @user.id == session[:password_reset_user] && @user.valid_password_reset_token?(token)

    login_failure(t("passwords.edit.token_failure"))
  end

  def password_reset_requires_mfa?
    @user.mfa_enabled? && session[:password_reset_reason] != "compromised" && !password_reset_verification_active?
  end

  def mark_password_reset_verified
    session[:password_reset_verified] = Gemcutter::PASSWORD_VERIFICATION_EXPIRY.from_now
  end

  def complete_password_reset_verification
    delete_mfa_session
    mark_password_reset_verified
    redirect_to reset_password_path
  end

  def password_reset_verification_active?
    session[:password_reset_verified].present? && Time.current.before?(session[:password_reset_verified])
  end

  def validate_password_reset_verification
    return login_failure(t("passwords.edit.token_failure")) if session[:password_reset_verified].nil?
    login_failure(t("verification_expired")) if Time.current.after?(session[:password_reset_verified])
  end

  def delete_password_reset_session
    delete_mfa_session
    session.delete(:password_reset_user)
    session.delete(:password_reset_token)
    session.delete(:password_reset_verified)
    session.delete(:password_reset_reason)
  end

  def reset_params
    params.expect(password_reset: %i[password reset_api_key reset_api_keys])
  end

  def mfa_failure(message)
    prompt_mfa(alert: message, status: :unauthorized)
  end

  def login_failure(alert)
    reset_session
    redirect_to sign_in_path, alert:
  end

  def otp_verification_url
    otp_edit_password_url
  end

  def webauthn_verification_url
    webauthn_edit_password_url
  end
end
