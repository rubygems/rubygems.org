# frozen_string_literal: true

class CompromisedPasswordsController < ApplicationController
  layout "hammy"

  before_action :validate_session

  def show
    @user = User.find_by(id: session[:compromised_password_user_id])
    return redirect_to sign_in_path unless @user
    StatsD.increment "login.password_compromised.page_view"
  end

  private

  def validate_session
    redirect_to sign_in_path if session[:compromised_password_user_id].blank?
  end
end
