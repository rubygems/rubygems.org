class EmailConfirmationsController < ApplicationController
  before_action :validate_confirmation_token, only: :update

  def update
    @user.confirm_email!
    sign_in @user
    redirect_to root_path, notice: t('.confirmed_email')
  end

  def new
  end

  # used to resend confirmation mail for email validation
  def create
    user = User.find_by_email(params[:email_confirmation][:email])
    if user
      user.set_confirmation_token
      Mailer.delay.email_confirmation(user) if user.save
    end
    redirect_to root_path, notice: t('.promise_resend')
  end

  private

  def validate_confirmation_token
    @user = User.find_by_confirmation_token(params[:token])
    return if @user&.valid_confirmation_token?
    redirect_to root_path, alert: t('failure_when_forbidden')
  end
end
