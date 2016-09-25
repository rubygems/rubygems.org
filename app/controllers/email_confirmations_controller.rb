class EmailConfirmationsController < ApplicationController
  before_action :validate_confirmation_token, only: :update

  def update
    @user.confirm_email
    sign_in @user
    redirect_to root_path, notice: t('mailer.confirmed_email')
  end

  def validate_confirmation_token
    @user = User.find_by_confirmation_token(params[:token])
    return if @user&.valid_confirmation_token?
    redirect_to root_path, alert: t('failure_when_forbidden')
  end
end
