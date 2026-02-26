class CompromisedPasswordsController < ApplicationController
  layout "hammy"

  before_action :validate_session

  def show
    @user = User.find_by(id: session[:compromised_password_user_id])
    return redirect_to sign_in_path unless @user
  end

  private

  def validate_session
    redirect_to sign_in_path if session[:compromised_password_user_id].blank?
  end
end
