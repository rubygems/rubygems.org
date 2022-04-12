class EmailConfirmationsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?, only: :unconfirmed
  before_action :validate_confirmation_token, only: %i[update mfa_update]

  def update
    if @user.mfa_enabled?
      @form_url = mfa_update_email_confirmations_url(token: @user.confirmation_token)
      render template: "multifactor_auths/otp_prompt"
    else
      confirm_email
    end
  end

  def mfa_update
    if @user.mfa_enabled? && @user.otp_verified?(params[:otp])
      confirm_email
    else
      @form_url       = mfa_update_email_confirmations_url(token: @user.confirmation_token)
      flash.now.alert = t("multifactor_auths.incorrect_otp")
      render template: "multifactor_auths/otp_prompt", status: :unauthorized
    end
  end

  def new
  end

  # used to resend confirmation mail for email validation
  def create
    user = find_user_for_create

    if user
      user.generate_confirmation_token
      Delayed::Job.enqueue(EmailConfirmationMailer.new(user.id)) if user.save
    end
    redirect_to root_path, notice: t(".promise_resend")
  end

  # used to resend confirmation mail for unconfirmed_email validation
  def unconfirmed
    if current_user.generate_confirmation_token && current_user.save
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
end
