class EmailConfirmationsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?, only: :unconfirmed
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: :unconfirmed
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: :unconfirmed
  before_action :validate_confirmation_token, only: %i[update mfa_update webauthn_update]

  def update
    if @user.mfa_enabled? || @user.webauthn_credentials.any?
      setup_mfa_authentication
      setup_webauthn_authentication

      render template: "multifactor_auths/mfa_prompt"
    else
      confirm_email
    end
  end

  def mfa_update
    if mfa_update_conditions_met?
      confirm_email
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  def webauthn_update
    @challenge = session.dig(:webauthn_authentication, "challenge")

    if params[:credentials].blank?
      login_failure(t("credentials_required"))
      return
    end

    @credential = WebAuthn::Credential.from_get(params[:credentials])

    @webauthn_credential = @user.webauthn_credentials.find_by(
      external_id: @credential.id
    )

    @credential.verify(
      @challenge,
      public_key: @webauthn_credential.public_key,
      sign_count: @webauthn_credential.sign_count
    )

    @webauthn_credential.update!(sign_count: @credential.sign_count)

    confirm_email
  rescue WebAuthn::Error => e
    login_failure(e.message)
  end

  def new
  end

  # used to resend confirmation mail for email validation
  def create
    user = find_user_for_create

    if user
      user.generate_confirmation_token(reset_unconfirmed_email: false)
      Delayed::Job.enqueue(EmailConfirmationMailer.new(user.id)) if user.save
    end
    redirect_to root_path, notice: t(".promise_resend")
  end

  # used to resend confirmation mail for unconfirmed_email validation
  def unconfirmed
    if current_user.generate_confirmation_token(reset_unconfirmed_email: false) && current_user.save
      Delayed::Job.enqueue EmailResetMailer.new(current_user.id)
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
    @user.mfa_enabled? && @user.otp_verified?(params[:otp])
  end

  def setup_mfa_authentication
    return if @user.mfa_disabled?
    @form_mfa_url = mfa_update_email_confirmations_url(token: @user.confirmation_token)
  end

  def setup_webauthn_authentication
    return if @user.webauthn_credentials.none?

    @form_webauthn_url = webauthn_update_email_confirmations_url(token: @user.confirmation_token)

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge
    }
  end

  def login_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/mfa_prompt", status: :unauthorized
  end
end
