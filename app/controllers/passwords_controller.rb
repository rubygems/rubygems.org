class PasswordsController < Clearance::PasswordsController
  before_action :validate_confirmation_token, only: %i[edit mfa_edit webauthn_edit]

  def edit
    if @user.mfa_enabled? || @user.webauthn_credentials.any?
      setup_mfa_authentication
      setup_webauthn_authentication

      render template: "multifactor_auths/mfa_prompt"
    else
      render template: "passwords/edit"
    end
  end

  def update
    @user = find_user_for_update

    if @user.update_password password_from_password_reset_params
      @user.reset_api_key! if reset_params[:reset_api_key] == "true"
      @user.api_keys.delete_all if reset_params[:reset_api_keys] == "true"
      sign_in @user
      redirect_to url_after_update
      session[:password_reset_token] = nil
    else
      flash_failure_after_update
      render template: "passwords/edit"
    end
  end

  def mfa_edit
    if mfa_edit_conditions_met?
      render template: "passwords/edit"
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  def webauthn_edit
    @challenge = session.dig(:webauthn_authentication, "challenge")

    if params[:credentials].blank?
      login_failure(t("credentials_required"))
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
    render template: "passwords/edit"
  rescue WebAuthn::Error => e
    login_failure(e.message)
  end

  private

  def url_after_update
    dashboard_path
  end

  def reset_params
    params.fetch(:password_reset, {}).permit(:reset_api_key, :reset_api_keys)
  end

  def validate_confirmation_token
    @user = find_user_for_edit
    redirect_to root_path, alert: t("failure_when_forbidden") unless @user&.valid_confirmation_token?
  end

  def deliver_email(user)
    mail = ::ClearanceMailer.change_password(user)
    mail.deliver_later
  end

  def setup_mfa_authentication
    return if @user.mfa_disabled?
    @form_mfa_url = mfa_edit_user_password_url(@user, token: @user.confirmation_token)
  end

  def setup_webauthn_authentication
    return if @user.webauthn_credentials.none?

    @form_webauthn_url = webauthn_edit_user_password_url(@user, token: @user.confirmation_token)

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge
    }
  end

  def mfa_edit_conditions_met?
    @user.mfa_enabled? && @user.otp_verified?(params[:otp])
  end

  def login_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/mfa_prompt", status: :unauthorized
  end
end
