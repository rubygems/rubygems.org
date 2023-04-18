# This controller is for the user interface Webauthn challenge after a user follows a link generated
# by the APIv1 WebauthnVerificationsController (controllers/api/v1/webauthn_verifications_controller).
class WebauthnVerificationsController < ApplicationController
  include WebauthnVerifiable

  before_action :set_verification, :set_user, except: %i[successful_verification failed_verification]

  def prompt
    redirect_to root_path, alert: t(".no_port") unless (port = params[:port])
    redirect_to root_path, alert: t(".no_webauthn_devices") if @user.webauthn_credentials.blank?

    setup_webauthn_authentication(session_options: { "port" => port })
  end

  def authenticate
    port = session.dig(:webauthn_authentication, "port")
    unless port
      redirect_to root_path, alert: t(".no_port")
      return
    end

    return render plain: @webauthn_error, status: :unauthorized unless webauthn_credential_verified?

    @verification.generate_otp
    @verification.expire_path_token

    redirect_to(URI.parse("http://localhost:#{port}?code=#{@verification.otp}").to_s, allow_other_host: true)
  end

  def failed_verification
    @message = params.permit(:error).fetch(:error, "")
    logger.info("WebAuthn Verification failed", error: @message)
  end

  private

  def set_verification
    @verification = WebauthnVerification.find_by(path_token: webauthn_token_param)

    render_not_found and return unless @verification
    render_expired if @verification.path_token_expired?
  end

  def set_user
    @user = @verification.user
  end

  def webauthn_token_param
    params.permit(:webauthn_token).require(:webauthn_token)
  end

  def render_expired
    respond_to do |format|
      format.html { redirect_to root_path, alert: t("webauthn_verifications.expired_or_already_used") }
      format.text { render plain: t("webauthn_verifications.expired_or_already_used"), status: :unauthorized }
    end
  end
end
