class PasswordsController < Clearance::PasswordsController
  before_action :validate_confirmation_token, only: %i[edit mfa_edit]

  def edit
    if @user.mfa_enabled?
      @form_url = mfa_edit_user_password_url(@user, token: @user.confirmation_token)
      render template: "multifactor_auths/otp_prompt"
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
    if @user.mfa_enabled? && @user.otp_verified?(params[:otp])
      render template: "passwords/edit"
    else
      @form_url       = mfa_edit_user_password_url(@user, token: @user.confirmation_token)
      flash.now.alert = t("multifactor_auths.incorrect_otp")
      render template: "multifactor_auths/otp_prompt", status: :unauthorized
    end
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
end
