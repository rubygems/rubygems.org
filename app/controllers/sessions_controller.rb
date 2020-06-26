class SessionsController < Clearance::SessionsController
  def create
    @user = find_user

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
      login_failure(t("multifactor_auths.incorrect_otp"), @user)
    end
  end

  def destroy
    Delayed::Job.enqueue(
      Castle::LogoutSucceeded.new(current_user, castle_context), priority: PRIORITIES[:stats]
    )
    super
  end

  private

  def do_login
    sign_in(@user) do |status|
      if status.success?
        login_success
      else
        failed_user = User.find_by_name(session_params.dig(:who))
        login_failure(status.failure_message, failed_user)
      end
    end
  end

  def castle_context
    ::Castle::Client.to_context(request)
  end

  def login_success
    StatsD.increment "login.success"
    Delayed::Job.enqueue(
      Castle::LoginSucceeded.new(@user, castle_context), priority: PRIORITIES[:stats]
    )
    redirect_back_or(url_after_create)
  end

  def login_failure(message, failed_user)
    StatsD.increment "login.failure"
    Delayed::Job.enqueue(
      Castle::LoginFailed.new(failed_user, castle_context), priority: PRIORITIES[:stats]
    )
    flash.now.notice = message
    render template: "sessions/new", status: :unauthorized
  end

  def find_user
    who = session_params[:who].is_a?(String) && session_params.fetch(:who)
    password = session_params[:password].is_a?(String) && session_params.fetch(:password)

    User.authenticate(who, password) if who && password
  end

  def url_after_create
    dashboard_path
  end

  def session_params
    params.require(:session).permit(:who, :password)
  end
end
