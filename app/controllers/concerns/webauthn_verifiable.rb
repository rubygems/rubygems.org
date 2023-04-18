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
    @challenge = session.dig(:webauthn_authentication, "challenge")

    if params[:credentials].blank?
      @webauthn_error = t("credentials_required")
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
