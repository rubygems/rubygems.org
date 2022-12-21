class Api::V1::WebauthnVerificationsController < Api::BaseController
  def create
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username.strip, password)

      if user
        if user.webauthn_credentials.present?
          token = user.refresh_webauthn_verification.path_token
          webauthn_path = "example.com/webauthn/#{token}"
          respond_to do |format|
            format.any(:all) { render plain: webauthn_path }
            format.yaml { render yaml: { path: webauthn_path } }
            format.json { render json: { path: webauthn_path } }
          end
        else
          render plain: t("settings.edit.no_webauthn_credentials"), status: :unprocessable_entity
        end
      else
        false
      end
    end
  end
end
