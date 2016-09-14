class EmailConfirmationsController < ApplicationController
  def update
    user = User.find_by!(confirmation_token: params[:token])
    user.confirm_email
    sign_in user
    redirect_to root_path, notice: t('mailer.confirmed_email')
  end
end
