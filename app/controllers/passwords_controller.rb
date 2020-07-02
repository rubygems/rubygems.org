class PasswordsController < Clearance::PasswordsController
  include CastleTrack

  before_action :validate_confirmation_token, only: %i[edit mfa_edit]

  def create
    super
    track_castle_event(Castle::ProfileUpdateSucceeded, @user)
  rescue ActionController::ParameterMissing => e
    track_castle_event(Castle::ProfileUpdateFailed, @user)
    render plain: "Request is missing param '#{e.param}'", status: :bad_request
  end

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
      track_castle_event(Castle::ProfileUpdateSucceeded, @user)
      session[:password_reset_token] = nil
    else
      flash_failure_after_update
      track_castle_event(Castle::ProfileUpdateFailed, @user)
      render template: "passwords/edit"
    end
  rescue ActionController::ParameterMissing => e
    track_castle_event(Castle::ProfileUpdateFailed, @user)
    render plain: "Request is missing param '#{e.param}'", status: :bad_request
  end

  def mfa_edit
    if @user.mfa_enabled? && @user.otp_verified?(params[:otp])
      track_castle_event(Castle::ProfileUpdateSucceeded, @user)
      render template: "passwords/edit"
    else
      track_castle_event(Castle::ProfileUpdateFailed, @user)
      flash.now.alert = t("multifactor_auths.incorrect_otp")
      render template: "passwords/otp_prompt", status: :unauthorized
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

  def reset_params
    params.fetch(:password_reset, {}).permit(:reset_api_key)
  end

  def validate_confirmation_token
    @user = find_user_for_edit
    redirect_to root_path, alert: t("failure_when_forbidden") unless @user&.valid_confirmation_token?
  end
end
