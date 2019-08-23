class WebauthnCredentialsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?

  def index
    @user = current_user
  end

  def create_options
    credential_options = WebAuthn.credential_creation_options(
      user_name: current_user.handle,
      display_name: current_user.handle,
      user_id: bin_to_str(current_user.handle)
    )

    credential_options[:challenge] = bin_to_str(credential_options[:challenge])
    session[:webauthn_challenge] = credential_options[:challenge]

    respond_to do |format|
      format.json { render json: credential_options }
    end
  end

  def create
    current_challenge = session[:webauthn_challenge]
    public_key_credential = WebAuthn::PublicKeyCredential.from_create(params, encoding: :base64url)

    if public_key_credential.verify(str_to_bin(current_challenge))
      credential = current_user.webauthn_credentials.build(
        external_id: bin_to_str(public_key_credential.raw_id),
        public_key: bin_to_str(public_key_credential.public_key),
        nickname: params[:nickname],
        sign_count: public_key_credential.sign_count
      )
      if credential.save
        flash[:success] = t(".success")
        status = :ok
      else
        flash[:error] = t(".problem")
        status = :internal_server_error
      end
    else
      flash[:error] = t(".problem")
      status = :unprocessable_entity
    end

    render json: { status: status, redirect_path: webauthn_credentials_path }, status: status
  end

  def destroy
    begin
      current_user.webauthn_credentials.find(params[:id]).destroy
      flash[:success] = t(".success")
    rescue ActiveRecord::RecordNotFound
      flash[:error] = t(".not_found")
    end
    redirect_to webauthn_credentials_url
  end
end
