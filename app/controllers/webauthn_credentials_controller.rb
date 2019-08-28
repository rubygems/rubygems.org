class WebauthnCredentialsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?

  def index
    @user = current_user
  end

  def destroy
    begin
      current_user.webauthn_credentials.find(params[:id]).destroy
      flash[:success] = t(".success")
    rescue ActiveRecord::RecordNotFound
      flash[:error] = t(".not_found")
    end
    redirect_to webauthn_credentials_url
  end
end
