class CompromisedPasswordsController < ApplicationController
  layout "hammy"

  before_action :validate_session

  def show
    @user = User.find_by(id: session[:compromised_password_user_id])
    return redirect_to sign_in_path unless @user

    # Send password reset email if not already sent
    return if session[:compromised_password_email_sent]
    @user.generate_password_reset_token!
    PasswordMailer.compromised_password_reset(@user).deliver_later
    session[:compromised_password_email_sent] = true
  end

  private

  def validate_session
    redirect_to sign_in_path if session[:compromised_password_user_id].blank?
  end
end
