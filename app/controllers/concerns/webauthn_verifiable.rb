module WebauthnVerifiable
  extend ActiveSupport::Concern

  def setup_webauthn_authentication
    return if @user.webauthn_credentials.none?

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge,
      "user" => @user.id
    }
  end

  def verify_webauthn_credential
    @user = User.find(session.dig(:webauthn_authentication, "user"))
    @challenge = session.dig(:webauthn_authentication, "challenge")

    if params[:credentials].blank?
      webauthn_verification_failure(t("credentials_required"))
      return
    elsif !session_active?
      webauthn_verification_failure(t("multifactor_auths.session_expired"))
      return
    end

    @credential = WebAuthn::Credential.from_get(params[:credentials])

    @webauthn_credential = @user.webauthn_credentials.find_by(
      external_id: @credential.id
    )

    @credential.verify(
      @challenge,
      public_key: @webauthn_credential.public_key,
      sign_count: @webauthn_credential.sign_count
    )

    @webauthn_credential.update!(sign_count: @credential.sign_count)
  end
end
