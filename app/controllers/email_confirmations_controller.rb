# frozen_string_literal: true

class EmailConfirmationsController < ApplicationController
  include EmailResettable
  include RequireMfa
  include MfaExpiryMethods
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?, only: :unconfirmed
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: :unconfirmed
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: :unconfirmed
  prepend_before_action :protect_email_confirmation_response, only: %i[update confirm otp_update webauthn_update]
  before_action :begin_email_confirmation, only: :update
  before_action :load_email_confirmation, only: %i[confirm otp_update webauthn_update]
  before_action :require_mfa, only: :confirm
  before_action :validate_otp, only: :otp_update
  before_action :validate_webauthn, only: :webauthn_update
  after_action :delete_mfa_expiry_session, only: %i[otp_update webauthn_update]

  def new
  end

  # used to resend confirmation mail for email validation
  def create
    user = find_user_for_create

    if user
      user.invalidate_email_confirmation!
      Mailer.email_confirmation(user, user.email).deliver_later
    end
    redirect_to root_path, notice: t(".promise_resend")
  end

  def update
    render :update
  end

  def confirm
    confirm_email
  end

  def otp_update
    confirm_email
  end

  def webauthn_update
    confirm_email
  end

  # used to resend confirmation mail for unconfirmed_email validation
  def unconfirmed
    if current_user.unconfirmed_email?
      current_user.invalidate_email_confirmation!
      email_reset(current_user)
      flash[:notice] = t("profiles.update.confirmation_mail_sent")
    else
      flash[:notice] = t("try_again")
    end
    redirect_to edit_profile_path
  end

  private

  def find_user_for_create
    Clearance.configuration.user_model.where(email_confirmed: false).find_by_normalized_email email_params
  end

  def begin_email_confirmation
    token = token_params.to_s
    @user = User.find_by_email_confirmation_token(token)
    return login_failure(t("email_confirmations.update.token_failure")) unless @user&.valid_email_confirmation_token?(token)

    sign_out if signed_in? && @user != current_user
    session[:email_confirmation_user] = @user.id
    session[:email_confirmation_token] = token
  end

  def load_email_confirmation
    token = session[:email_confirmation_token]
    @user = User.find_by_email_confirmation_token(token)
    return if @user&.id == session[:email_confirmation_user] && @user&.valid_email_confirmation_token?(token)

    login_failure(t("email_confirmations.update.token_failure"))
  end

  def confirm_email
    case @user.confirm_email_with_token(session[:email_confirmation_token])
    when :confirmed
      delete_email_confirmation_session
      redirect_to signed_in? ? dashboard_path : sign_in_path, notice: t("email_confirmations.update.confirmed_email")
    when :invalid_email
      redirect_to signed_in? ? dashboard_path : sign_in_path, alert: @user.errors.full_messages.to_sentence
    else
      login_failure(t("email_confirmations.update.token_failure"))
    end
  end

  def email_params
    params.expect(email_confirmation: :email).require(:email)
  end

  def token_params
    params.expect(:token)
  end

  def login_failure(message)
    delete_email_confirmation_session
    redirect_to root_path, alert: message
  end

  def otp_verification_url
    otp_update_email_confirmations_url
  end

  def webauthn_verification_url
    webauthn_update_email_confirmations_url
  end

  def mfa_failure(alert)
    prompt_mfa(alert:, status: :unauthorized)
  end

  def protect_email_confirmation_response
    disable_cache
    no_referrer
    response.headers["Cache-Control"] = "private, no-store"
    response.headers["Surrogate-Control"] = "no-store"
  end

  def delete_email_confirmation_session
    delete_mfa_session
    session.delete(:email_confirmation_user)
    session.delete(:email_confirmation_token)
  end
end
