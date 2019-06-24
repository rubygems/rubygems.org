class SessionsController < Clearance::SessionsController
  def create
    @user = find_user(params.require(:session))

    if @user&.mfa_enabled?
      session[:mfa_user] = @user.handle
      render "sessions/otp_prompt"
    else
      do_login
    end
  end

  def mfa_create
    @user = User.find_by_name(session[:mfa_user])
    session.delete(:mfa_user)

    if @user&.mfa_enabled? && @user&.otp_verified?(params[:otp])
      do_login
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  private

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

  def find_user(session)
    who = session[:who].is_a?(String) && session.fetch(:who)
    password = session[:password].is_a?(String) && session.fetch(:password)

    User.authenticate(who, password) if who && password
  end

  def url_after_create
    dashboard_path
  end
end
