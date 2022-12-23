class WebauthnVerificationsController < ApplicationController
  before_action :set_user, only: :verify

  def verify
    # TODO: Verify webauthn
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
