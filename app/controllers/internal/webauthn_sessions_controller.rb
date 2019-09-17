class Internal::WebauthnSessionsController < Clearance::SessionsController
  def options
    user = User.find_by(handle: session[:mfa_user])

    if user&.webauthn_enabled?
      options_for_get = WebAuthn::Credential.options_for_get(
        allow: user.webauthn_credentials.pluck(:external_id)
      )

      session[:webauthn_challenge] = options_for_get.challenge

      render json: options_for_get, status: :ok
    else
      flash[:error] = t("webauthn_credentials.not_enabled")
      render json: { redirect_path: sign_in_path }, status: :unauthorized
    end
  end

  def create
    user = User.find_by(handle: session[:mfa_user])
    session.delete(:mfa_user)

    webauthn_credential = WebAuthn::Credential.from_get(params)

    if user&.webauthn_enabled? && user&.webauthn_verified?(session[:webauthn_challenge], webauthn_credential)
      user_credential = user.webauthn_credentials.find_by(external_id: webauthn_credential.id)
      new_sign_count = webauthn_credential.sign_count
      attributes_to_update = { last_used_on: Time.now.in_time_zone }
      attributes_to_update[:sign_count] = new_sign_count if new_sign_count
      user_credential.update!(attributes_to_update)

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
