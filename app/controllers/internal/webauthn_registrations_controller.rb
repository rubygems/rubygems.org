class Internal::WebauthnRegistrationsController < ApplicationController
  def options
    current_user.update(webauthn_handle: WebAuthn.generate_user_id) unless current_user.webauthn_handle

    credential_options = WebAuthn::Credential.options_for_create(
      user: {
        name: current_user.handle,
        display_name: current_user.handle,
        id: current_user.webauthn_handle
      },
      exclude: current_user.webauthn_credentials.pluck(:external_id)
    )

    session[:webauthn_challenge] = credential_options.challenge

    render json: credential_options, status: :ok
  end

  def create
    public_key_credential = WebAuthn::Credential.from_create(params)

    if public_key_credential.verify(session[:webauthn_challenge])
      credential = current_user.webauthn_credentials.build(
        external_id: public_key_credential.id,
        public_key: public_key_credential.public_key,
        nickname: params[:nickname],
        sign_count: public_key_credential.sign_count
      )
      if credential.save
        flash[:success] = t(".success")
        status = :ok
      else
        flash[:error] = t(".fail")
        status = :internal_server_error
      end
    else
      flash[:error] = t("internal.webauthn_sessions.incorrect_security_key")
      status = :unauthorized
    end

    render json: { redirect_path: webauthn_credentials_path }, status: status
  end
end
