class EmailConfirmationsController < ApplicationController
  def update
    user = User.find_by(confirmation_token: params[:token])

    if user&.valid_confirmation_token? && user.confirm_email!
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
    user = User.find_by(email: confirmation_params[:email])

    if user
      user.regenerate_confirmation_token
      Mailer.delay.email_confirmation(user) if user.save
    end
    redirect_to root_path, notice: t('.promise_resend')
  end

  private

  def confirmation_params
    params[:email_confirmation]
  end
end
