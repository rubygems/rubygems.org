class EmailConfirmationsController < ApplicationController
  include EmailResettable
  include MfaExpiryMethods
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?, only: :unconfirmed
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: :unconfirmed
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: :unconfirmed
  before_action :validate_confirmation_token, only: %i[update mfa_update webauthn_update]
  after_action :delete_mfa_expiry_session, only: %i[mfa_update webauthn_update]

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
    if @user.mfa_enabled? || @user.webauthn_credentials.any?
      setup_mfa_authentication
      setup_webauthn_authentication(form_url: webauthn_update_email_confirmations_url(token: @user.confirmation_token))

      create_new_mfa_expiry

      render template: "multifactor_auths/mfa_prompt"
    else
      confirm_email
    end
  end

  def mfa_update
    if mfa_update_conditions_met?
      confirm_email
    elsif !session_active?
      login_failure(t("multifactor_auths.session_expired"))
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  def webauthn_update
    unless session_active?
      login_failure(t("multifactor_auths.session_expired"))
      return
    end

    return login_failure(@webauthn_error) unless webauthn_credential_verified?

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
    redirect_to root_path, alert: t("failure_when_forbidden") unless @user&.valid_confirmation_token?
  end

  def confirm_email
    if @user.confirm_email!
      sign_in @user
      redirect_to root_path, notice: t("email_confirmations.update.confirmed_email")
    else
      redirect_to root_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def email_params
    params.permit(email_confirmation: :email).require(:email_confirmation).require(:email)
  end

  def token_params
    params.permit(:token).require(:token)
  end

  def mfa_update_conditions_met?
    @user.mfa_enabled? && @user.ui_mfa_verified?(params[:otp]) && session_active?
  end

  def setup_mfa_authentication
    return if @user.totp_disabled?
    @form_mfa_url = mfa_update_email_confirmations_url(token: @user.confirmation_token)
  end

  def login_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/mfa_prompt", status: :unauthorized
  end
end
