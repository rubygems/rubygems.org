class WebauthnVerificationsController < ApplicationController
  before_action :set_user, only: :prompt

  def prompt
    redirect_to root_path, alert: t("webauthn_verification.prompt.no_webauthn_devices") if @user.webauthn_credentials.blank?

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge,
      "user" => @user.id
    }
  end

  private

  def set_user
    verification = WebauthnVerification.find_by(path_token: webauthn_token_param)
    if !verification || verification.path_token_expires_at < Time.now.utc
      render_not_found
    else
      @user = verification.user
    end
  end

  def webauthn_token_param
    params.permit(:webauthn_token).require(:webauthn_token)
  end
end
