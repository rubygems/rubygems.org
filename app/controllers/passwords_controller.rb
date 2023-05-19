class PasswordsController < Clearance::PasswordsController
  include MfaExpiryMethods
  include WebauthnVerifiable

  before_action :validate_confirmation_token, only: %i[edit mfa_edit webauthn_edit]
  after_action :delete_mfa_expiry_session, only: %i[mfa_edit webauthn_edit]

  def edit
    if @user.mfa_enabled? || @user.webauthn_credentials.any?
      setup_mfa_authentication
      setup_webauthn_authentication(form_url: webauthn_edit_user_password_url(token: @user.confirmation_token))

      create_new_mfa_expiry

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
    elsif !session_active?
      login_failure(t("multifactor_auths.session_expired"))
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  def webauthn_edit
    unless session_active?
      login_failure(t("multifactor_auths.session_expired"))
      return
    end

    return login_failure(@webauthn_error) unless webauthn_credential_verified?

    render template: "passwords/edit"
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
    ::ClearanceMailer.change_password(user).deliver_later
  end

  def setup_mfa_authentication
    return if @user.mfa_disabled?
    @form_mfa_url = mfa_edit_user_password_url(@user, token: @user.confirmation_token)
  end

  def mfa_edit_conditions_met?
    @user.mfa_enabled? && @user.ui_mfa_verified?(params[:otp]) && session_active?
  end

  def login_failure(message)
    flash.now.alert = message
    render template: "multifactor_auths/mfa_prompt", status: :unauthorized
  end
end
