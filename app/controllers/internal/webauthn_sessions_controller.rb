class Internal::WebauthnSessionsController < Clearance::SessionsController
  def options
    user = User.find_by(handle: session[:mfa_user])

    if user&.webauthn_enabled?
      credentials_request_options = WebAuthn.credential_request_options
      credentials_request_options[:allowCredentials] = user.webauthn_credentials.map do |cred|
        { id: cred.external_id, type: "public-key" }
      end

      credentials_request_options[:challenge] = bin_to_str(credentials_request_options[:challenge])
      session[:webauthn_challenge] = credentials_request_options[:challenge]

      render json: credentials_request_options, status: :ok
    else
      flash[:error] = t("webauthn_credentials.not_enabled")
      render json: { redirect_path: sign_in_path }, status: :unauthorized
    end
  end

  def create
    user = User.find_by(handle: session[:mfa_user])
    session.delete(:mfa_user)

    public_key_credential = WebAuthn::PublicKeyCredential.from_get(params, encoding: :base64url)
    current_challenge = session[:webauthn_challenge]

    if user&.webauthn_enabled? && user&.webauthn_verified?(current_challenge, public_key_credential)
      credential = user.webauthn_credentials.find_by(external_id: public_key_credential.id)
      new_sign_count = public_key_credential.sign_count
      credential.update!(sign_count: new_sign_count) if new_sign_count

      sign_in(user) do |status|
        if status.success?
          render json: { redirect_path: root_path }, status: :ok
        else
          flash[:notice] = status.failure_message
          render json: { redirect_path: sign_in_path }
        end
      end
    else
      flash[:error] = t("internal.webauthn_sessions.incorrect_security_key")
      render json: { redirect_path: sign_in_path }, status: :unauthorized
    end
  end
end
