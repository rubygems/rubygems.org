module WebauthnVerifiable
  extend ActiveSupport::Concern

  def setup_webauthn_authentication(form_url:, session_options: {})
    return if @user.webauthn_credentials.none?

    @webauthn_options = @user.webauthn_options_for_get
    @webauthn_verification_url = form_url

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge
    }.merge(session_options)
  end

  def webauthn_credential_verified?
    @credential = WebAuthn::Credential.from_get(credential_params)

    unless user_webauthn_credential
      @webauthn_error = t("credentials_required")
      return false
    end

    @credential.verify(
      challenge,
      public_key: user_webauthn_credential.public_key,
      sign_count: user_webauthn_credential.sign_count
    )
    user_webauthn_credential.update!(sign_count: @credential.sign_count)

    if @credential.user_handle.present? && @credential.user_handle != user_webauthn_credential.user.webauthn_id
      @webauthn_error = t("credentials_required")
      return false
    end

    true
  rescue WebAuthn::Error => e
    @webauthn_error = e.message
    false
  rescue ActionController::ParameterMissing
    @webauthn_error = t("credentials_required")
    false
  ensure
    session.delete(:webauthn_authentication)
  end

  private

  def webauthn_credential_scope
    if @user.present?
      @user.webauthn_credentials
    else
      User.find_by(webauthn_id: @credential.user_handle)&.webauthn_credentials || WebauthnCredential.none
    end
  end

  def user_webauthn_credential
    @user_webauthn_credential ||= webauthn_credential_scope.find_by(
      external_id: @credential.id
    )
  end

  def challenge
    session.dig(:webauthn_authentication, "challenge")
  end

  def credential_params
    params.permit(credentials: PERMITTED_CREDENTIALS).require(:credentials)
  end

  PERMITTED_CREDENTIALS = [
    :id,
    :type,
    :rawId,
    :authenticatorAttachment,
    { response: %i[authenticatorData attestationObject clientDataJSON signature userHandle] }
  ].freeze
end
