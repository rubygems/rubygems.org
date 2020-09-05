class PasswordsController < Clearance::PasswordsController
  before_action :validate_confirmation_token, only: %i[edit mfa_edit]
  before_action :redirect_to_signin, unless: :signed_in?, only: %i[show verify]

  def edit
    if @user.mfa_enabled?
      render template: "passwords/otp_prompt"
    else
      render template: "passwords/edit"
    end
  end

  def update
    @user = find_user_for_update

    if @user.update_password password_reset_params
      @user.reset_api_key! if reset_params[:reset_api_key] == "true"
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
      flash.now.alert = t("multifactor_auths.incorrect_otp")
      render template: "passwords/otp_prompt", status: :unauthorized
    end
  end

  def show
  end

  def verify
    if verify_user
      session[:verification] = Time.current + Gemcutter::PASSWORD_VERIFICATION_EXPIRY
      redirect_to session.delete(:redirect_uri) || root_path
    else
      redirect_to user_password_path(current_user), alert: t("profiles.request_denied")
    end
  end

  private

  def verify_user
    current_user.authenticated? verify_password_params[:password]
  end

  def find_user_for_create
    Clearance.configuration.user_model
      .find_by_normalized_email password_params[:email]
  end

  def url_after_update
    dashboard_path
  end

  def password_params
    params.require(:password).permit(:email)
  end

  def verify_password_params
    params.require(:verify_password).permit(:password)
  end

  def reset_params
    params.fetch(:password_reset, {}).permit(:reset_api_key)
  end

  def validate_confirmation_token
    @user = find_user_for_edit
    redirect_to root_path, alert: t("failure_when_forbidden") unless @user&.valid_confirmation_token?
  end
end
