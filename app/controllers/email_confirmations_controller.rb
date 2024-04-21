class EmailConfirmationsController < ApplicationController
  include EmailResettable
  include MfaExpiryMethods
  include WebauthnVerifiable

  before_action :redirect_to_signin, unless: :signed_in?, only: :unconfirmed
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: :unconfirmed
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: :unconfirmed

  before_action :validate_confirmation_token, only: %i[update]
  before_action :initiate_email_confirmation, only: %i[update]
  before_action :require_mfa, only: %i[update]

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
    if @user.confirm_email!
      sign_in @user
      redirect_to root_path, notice: t(".confirmed_email")
    else
      redirect_to root_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  # used to resend confirmation mail for unconfirmed_email validation
  def unconfirmed
    if current_user.generate_confirmation_token(reset_unconfirmed_email: false) && current_user.save
      email_reset(current_user)
      session[:email_confirmation_token] = nil
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

  def confirmation_token
    params.permit(:token).fetch(:token, session[:email_confirmation_token]).to_s
  end

  def validate_confirmation_token
    @user = User.find_by(confirmation_token:)
    invalidate_session(t("email_confirmations.update.token_failure")) unless @user&.valid_confirmation_token?
  end

  def initiate_email_confirmation
    return unless params[:token] && @user.mfa_enabled?
    initialize_mfa
    session[:email_confirmation_token] = params[:token]
    redirect_to url_for
  end

  def invalidate_session(reason)
    @user&.invalidate_confirmation_token!(confirmation_token)
    session.delete(:email_confirmation_token)
    redirect_to root_path, alert: reason
  end

  def email_params
    params.permit(email_confirmation: :email).require(:email_confirmation).require(:email)
  end
end
