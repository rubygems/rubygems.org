class WebauthnCredentialsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?

  def index
    @user = current_user
  end

  def destroy
    credential = current_user.webauthn_credentials.find_by(id: params[:id])
    if credential
      credential.destroy
      if credential.destroyed?
        flash[:success] = t(".success")
      else
        flash[:error] = t(".fail")
      end
    else
      flash[:error] = t(".not_found")
    end
    redirect_to webauthn_credentials_url
  end
end
