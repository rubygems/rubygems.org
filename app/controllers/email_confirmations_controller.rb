class EmailConfirmationsController < ApplicationController
  include EmailResettable
  include RequireMfa
  include MfaExpiryMethods
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?, only: :unconfirmed
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: :unconfirmed
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: :unconfirmed
  before_action :no_referrer, only: %i[update otp_update webauthn_update]
  before_action :validate_confirmation_token, only: %i[update otp_update webauthn_update]
  before_action :require_mfa, only: :update
  before_action :validate_otp, only: :otp_update
  before_action :validate_webauthn, only: :webauthn_update
  after_action :delete_mfa_expiry_session, only: %i[otp_update webauthn_update]

  def new
  end

  # used to resend confirmation mail for email validation
  def create
    user = find_user_for_create

    if user
      user.generate_confirmation_token(reset_unconfirmed_email: false)
      Mailer.email_confirmation(user).deliver_later if user.save
    end
    redirect_to root_path, notice: t(".promise_resend")
  end

  def update
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
    if current_user.generate_confirmation_token(reset_unconfirmed_email: false) && current_user.save
      email_reset(current_user)
      flash[:notice] = t("profiles.update.confirmation_mail_sent")
    else
      flash[:notice] = t("try_again")
    end
    redirect_to edit_profile_path
  end

  private

  def find_user_for_create
    Clearance.configuration.user_model.find_by_normalized_email email_params
  end

  def validate_confirmation_token
    @user = User.find_by(confirmation_token: token_params)
    redirect_to root_path, alert: t("email_confirmations.update.token_failure") unless @user&.valid_confirmation_token?
  end

  def confirm_email
    if @user.confirm_email!
      flash[:notice] = t("email_confirmations.update.confirmed_email")
    else
      flash[:alert] = @user.errors.full_messages.to_sentence
    end
    redirect_to signed_in? ? dashboard_path : sign_in_path
  end

  def email_params
    params.permit(email_confirmation: :email).require(:email_confirmation).require(:email)
  end

  def token_params
    params.permit(:token).require(:token)
  end

  def login_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/prompt", status: :unauthorized
  end

  def otp_verification_url
    otp_update_email_confirmations_url(token: @user.confirmation_token)
  end

  def webauthn_verification_url
    webauthn_update_email_confirmations_url(token: @user.confirmation_token)
  end

  def mfa_failure(alert)
    login_failure(alert)
  end
end
