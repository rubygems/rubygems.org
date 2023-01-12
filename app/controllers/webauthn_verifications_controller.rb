# This controller is for the user interface Webauthn challenge after a user follows a link generated
# by the APIv1 WebauthnVerificationsController (controllers/api/v1/webauthn_verifications_controller).
class WebauthnVerificationsController < ApplicationController
  before_action :set_verification, :set_user

  def prompt
    redirect_to root_path, alert: t(".no_webauthn_devices") if @user.webauthn_credentials.blank?

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge
    }
  end

  def authenticate
    # TODO: check if path token is expired
    webauthn_credential.verify(
      challenge,
      public_key: user_webauthn_credential.public_key,
      sign_count: user_webauthn_credential.sign_count
    )

    user_webauthn_credential.update!(sign_count: webauthn_credential.sign_count)
    # TODO: generate webauthn verification otp
    @webauthn_otp = 12_345

    @verification.expire_path_token

    render :success
  rescue WebAuthn::Error => e
    flash.now.notice = e.message
    render :prompt, status: :unauthorized
  rescue ActionController::ParameterMissing
    flash.now.notice = "Credentials required"
    render :prompt, status: :unauthorized
  ensure
    session.delete(:webauthn_authentication)
  end

  private

  def set_verification
    @verification = WebauthnVerification.find_by(path_token: webauthn_token_param)

    render_not_found and return unless @verification
    redirect_to root_path, alert: t(".expired_or_already_used") if @verification.path_token_expired?
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
end
