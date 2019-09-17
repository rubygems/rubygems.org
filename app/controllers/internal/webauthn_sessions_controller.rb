class Internal::WebauthnSessionsController < Clearance::SessionsController
  def options
    user = User.find_by(handle: session[:mfa_user])

    if user&.webauthn_enabled?
      credentials_request_options = WebAuthn::Credential.options_for_get(
        allow: user.webauthn_credentials.pluck(:external_id)
      )

      session[:webauthn_challenge] = credentials_request_options.challenge

      render json: credentials_request_options, status: :ok
    else
      flash[:error] = t("webauthn_credentials.not_enabled")
      render json: { redirect_path: sign_in_path }, status: :unauthorized
    end
  end

  def create
    user = User.find_by(handle: session[:mfa_user])
    session.delete(:mfa_user)

    public_key_credential = WebAuthn::Credential.from_get(params)

    if user&.webauthn_enabled? && user&.webauthn_verified?(session[:webauthn_challenge], public_key_credential)
      credential = user.webauthn_credentials.find_by(external_id: public_key_credential.id)
      new_sign_count = public_key_credential.sign_count
      attributes_to_update = { last_used_on: Time.now.in_time_zone }
      attributes_to_update[:sign_count] = new_sign_count if new_sign_count
      credential.update!(attributes_to_update)

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
