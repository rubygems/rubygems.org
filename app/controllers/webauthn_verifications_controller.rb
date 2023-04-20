# This controller is for the user interface Webauthn challenge after a user follows a link generated
# by the APIv1 WebauthnVerificationsController (controllers/api/v1/webauthn_verifications_controller).
class WebauthnVerificationsController < ApplicationController
  before_action :set_verification, :set_user, except: %i[successful_verification failed_verification]

  def prompt
    redirect_to root_path, alert: t(".no_port") unless (port = params[:port])
    redirect_to root_path, alert: t(".no_webauthn_devices") if @user.webauthn_credentials.blank?

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge,
      "port" => port
    }
  end

  def authenticate
    port = session.dig(:webauthn_authentication, "port")
    unless port
      redirect_to root_path, alert: t(".no_port")
      return
    end

    webauthn_credential.verify(
      challenge,
      public_key: user_webauthn_credential.public_key,
      sign_count: user_webauthn_credential.sign_count
    )

    user_webauthn_credential.update!(sign_count: webauthn_credential.sign_count)

    @verification.generate_otp
    @verification.expire_path_token

    redirect_to(URI.parse("http://localhost:#{port}?code=#{@verification.otp}").to_s, allow_other_host: true)
  rescue WebAuthn::Error => e
    render plain: e.message, status: :unauthorized
  rescue ActionController::ParameterMissing
    render plain: t("credentials_required"), status: :unauthorized
  ensure
    session.delete(:webauthn_authentication)
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

  def webauthn_credential
    @webauthn_credential ||= WebAuthn::Credential.from_get(credential_params)
  end

  def user_webauthn_credential
    @user_webauthn_credential ||= @user.webauthn_credentials.find_by(
      external_id: webauthn_credential.id
    )
  end

  def challenge
    session.dig(:webauthn_authentication, "challenge")
  end

  def credential_params
    @credential_params ||= params.require(:credentials).permit(
      :id,
      :type,
      :rawId,
      response: %i[authenticatorData attestationObject clientDataJSON signature]
    )
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
