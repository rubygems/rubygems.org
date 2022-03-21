class SessionsController < Clearance::SessionsController
  before_action :redirect_to_signin, unless: :signed_in?, only: %i[verify authenticate]
  before_action :ensure_not_blocked, only: :create

  def create
    @user = find_user

    if @user&.mfa_enabled?
      session[:mfa_user] = @user.display_id
      render "sessions/otp_prompt"
    else
      do_login
    end
  end

  def mfa_create
    @user = User.find_by_slug(session[:mfa_user])
    session.delete(:mfa_user)

    if @user&.mfa_enabled? && @user&.otp_verified?(params[:otp])
      do_login
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  def verify
  end

  def authenticate
    if verify_user
      session[:verification] = Time.current + Gemcutter::PASSWORD_VERIFICATION_EXPIRY
      redirect_to session.delete(:redirect_uri) || root_path
    else
      flash[:alert] = t("profiles.request_denied")
      render :verify, status: :unauthorized
    end
  end

  private

  def verify_user
    current_user.authenticated? verify_password_params[:password]
  end

  def verify_password_params
    params.require(:verify_password).permit(:password)
  end

  def do_login
    sign_in(@user) do |status|
      if status.success?
        StatsD.increment "login.success"
        redirect_back_or(url_after_create)
      else
        login_failure(status.failure_message)
      end
    end
  end

  def login_failure(message)
    StatsD.increment "login.failure"
    flash.now.notice = message
    render template: "sessions/new", status: :unauthorized
  end

  def session_params
    params.require(:session)
  end

  def find_user
    password = session_params[:password].is_a?(String) && session_params.fetch(:password)

    User.authenticate(who, password) if who && password
  end

  def who
    session_params[:who].is_a?(String) && session_params.fetch(:who)
  end

  def url_after_create
    if current_user.mfa_recommended_not_yet_enabled?
      flash[:notice] = t("multifactor_auths.setup_recommended")
      new_multifactor_auth_path
    elsif current_user.mfa_recommended_weak_level_enabled?
      flash[:notice] = t("multifactor_auths.strong_mfa_level_recommended")
      edit_settings_path
    else
      dashboard_path
    end
  end

  def ensure_not_blocked
    user = User.find_by_blocked(who)
    return unless user&.blocked_email

    flash.now.alert = t(".account_blocked")
    render template: "sessions/new", status: :unauthorized
  end
end
