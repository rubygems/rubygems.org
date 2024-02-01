# This controller generates a single-use link as part of the Webauthn CLI flow. It does not challenge
# the user with a Webauthn login. That is done in controllers/webauthn_verifications_controller.
class Api::V1::WebauthnVerificationsController < Api::BaseController
  before_action :authenticate_with_credentials
  before_action :set_cache_headers, only: :status

  def create
    if @user.webauthn_enabled?
      verification = @user.refresh_webauthn_verification
      webauthn_path = webauthn_verification_url(verification.path_token)
      respond_to do |format|
        format.any(:all) { render plain: webauthn_path }
        format.yaml { render yaml: { path: webauthn_path, expiry: verification.path_token_expires_at.utc } }
        format.json { render json: { path: webauthn_path, expiry: verification.path_token_expires_at.utc } }
      end
    else
      render plain: t("settings.edit.no_webauthn_credentials"), status: :unprocessable_entity
    end
  end

  def status
    verification = @user.webauthn_verification
    if verification.path_token != params[:webauthn_token]
      render json: { status: :not_found, message: t(:not_found) }
    elsif verification.otp_expired?
      render json: { status: :expired, message: t("webauthn_verifications.expired_or_already_used") }
    elsif verification.otp.nil?
      render json: { status: :pending, message: t("webauthn_verifications.pending") }
    else
      render json: { status: :success, code: verification.otp }
    end
  end

  private

  def authenticate_with_credentials
    params_key = request.headers["Authorization"] || ""
    hashed_key = Digest::SHA256.hexdigest(params_key)
    api_key = ApiKey.unexpired.find_by_hashed_key(hashed_key)

    @user = authenticated_user(api_key)
  end

  def authenticated_user(api_key)
    return api_key.user if api_key&.user?
    authenticate_or_request_with_http_basic do |username, password|
      User.authenticate(username.strip, password)
    end
  end
end
