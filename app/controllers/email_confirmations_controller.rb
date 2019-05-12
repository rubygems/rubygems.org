class EmailConfirmationsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?, only: :unconfirmed

  def update
    user = User.find_by(confirmation_token: params[:token])

    if user&.valid_confirmation_token? && user&.confirm_email!
      sign_in user
      redirect_to root_path, notice: t('.confirmed_email')
    else
      redirect_to root_path, alert: t('failure_when_forbidden')
    end
  end

  def new
  end

  # used to resend confirmation mail for email validation
  def create
    user = User.find_by(email: email_params)

    if user
      user.generate_confirmation_token
      Mailer.delay.email_confirmation(user) if user.save
    end
    redirect_to root_path, notice: t('.promise_resend')
  end

  # used to resend confirmation mail for unconfirmed_email validation
  def unconfirmed
    if current_user.generate_confirmation_token && current_user.save
      Mailer.delay.email_reset(current_user)
      flash[:notice] = t('profiles.update.confirmation_mail_sent')
    else
      flash[:notice] = t('try_again')
    end
    redirect_to edit_profile_path
  end

  private

  def email_params
    params.require(:email_confirmation).permit(:email).fetch(:email, "")
  end
end
