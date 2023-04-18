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

  def webauthn_credential_verified?
    @challenge = session.dig(:webauthn_authentication, "challenge")

    if params[:credentials].blank?
      @webauthn_error = t("credentials_required")
      return false
    elsif !session_active?
      @webauthn_error = t("multifactor_auths.session_expired")
      return false
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

    true
  rescue WebAuthn::Error => e
    @webauthn_error = e.message
    false
  ensure
    session.delete(:webauthn_authentication)
  end
end
