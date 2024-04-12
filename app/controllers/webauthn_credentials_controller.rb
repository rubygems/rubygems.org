class WebauthnCredentialsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?

  def create
    @create_options = current_user.webauthn_options_for_create

    session[:webauthn_registration] = { "challenge" => @create_options.challenge }

    render json: @create_options
  end

  def callback
    webauthn_credential = build_webauthn_credential

    if webauthn_credential.save
      flash[:notice] = t(".success")
      render_callback_redirect
    else
      message = webauthn_credential.errors.full_messages.to_sentence
      render json: { message: message }, status: :unprocessable_entity
    end
  rescue WebAuthn::Error => e
    render json: { message: e.message }, status: :unprocessable_entity
  ensure
    session.delete("webauthn_registration")
  end

  def destroy
    webauthn_credential = current_user.webauthn_credentials.find(params[:id])
    if webauthn_credential.destroy
      flash[:notice] = t(".webauthn_credential.confirm_delete")
    else
      flash[:error] = webauthn_credential.errors.full_messages.to_sentence
    end

    redirect_to edit_settings_path
  end

  private

  def webauthn_credential_params
    params.permit(webauthn_credential: :nickname).require(:webauthn_credential)
  end

  def build_webauthn_credential
    credential = WebAuthn::Credential.from_create(params.permit(credentials: {}).require(:credentials))
    credential.verify(session.dig(:webauthn_registration, "challenge").to_s)

    current_user.webauthn_credentials.build(
      webauthn_credential_params.merge(
        external_id: credential.id,
        public_key: credential.public_key,
        sign_count: credential.sign_count
      )
    )
  end

  def render_callback_redirect
    if current_user.mfa_device_count_one?
      session[:show_recovery_codes] = current_user.new_mfa_recovery_codes
      render json: { redirect_url: recovery_multifactor_auth_url }
    else
      render json: { redirect_url: edit_settings_url }
    end
  end
end
