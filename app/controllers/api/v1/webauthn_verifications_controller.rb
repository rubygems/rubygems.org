class Api::V1::WebauthnVerificationsController < Api::BaseController
  def create
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username.strip, password)

      if user&.webauthn_credentials.present?
        verification = user.refresh_webauthn_verification
        webauthn_path = "example.com/webauthn/#{verification.path_token}"
        respond_to do |format|
          format.any(:all) { render plain: webauthn_path }
          format.yaml { render yaml: { path: webauthn_path, expiry: verification.path_token_expires_at.utc } }
          format.json { render json: { path: webauthn_path, expiry: verification.path_token_expires_at.utc } }
        end
      elsif user # the user exists but hasn't configured any credentials
        render plain: t("settings.edit.no_webauthn_credentials"), status: :unprocessable_entity
      else # invalid user
        false
      end
    end
  end
end
