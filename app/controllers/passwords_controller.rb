class PasswordsController < Clearance::PasswordsController
  before_action :validate_confirmation_token, only: %i[edit mfa_edit]

  def edit
    if @user.mfa_enabled?
      render template: 'passwords/otp_prompt'
    else
      render template: 'passwords/edit'
    end
  end

  def mfa_edit
    if @user.mfa_enabled? && @user.otp_verified?(params[:otp])
      render template: 'passwords/edit'
    else
      flash.now.alert = t('multifactor_auths.incorrect_otp')
      render template: 'passwords/otp_prompt', status: :unauthorized
    end
  end

  private

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

  def validate_confirmation_token
    @user = find_user_for_edit
    redirect_to root_path, alert: t('failure_when_forbidden') unless @user&.valid_confirmation_token?
  end
end
