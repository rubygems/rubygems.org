class SessionsController < Clearance::SessionsController
  def create
    @user = find_user

    if @user&.mfa_enabled?
      session[:mfa_user] = @user.handle
      track_castle_event(Castle::ChallengeRequested, @user)
      render "sessions/otp_prompt"
    else
      do_login
    end
  end

  def mfa_create
    @user = User.find_by_name(session[:mfa_user])
    session.delete(:mfa_user)
    if @user&.mfa_enabled? && @user&.otp_verified?(params[:otp])
      track_castle_event(Castle::ChallengeSucceeded, @user)
      do_login
    else
      track_castle_event(Castle::ChallengeFailed, @user)
      login_failure(t("multifactor_auths.incorrect_otp"), @user)
    end
  end

  def destroy
    track_castle_event(Castle::LogoutSucceeded, current_user)
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

  def track_castle_event(castle_event, user)
    context = ::Castle::Client.to_context(request)
    Delayed::Job.enqueue(castle_event.new(user, context), priority: PRIORITIES[:stats])
  end

  def login_success
    StatsD.increment "login.success"
    track_castle_event(Castle::LoginSucceeded, @user)
    redirect_back_or(url_after_create)
  end

  def login_failure(message, failed_user)
    StatsD.increment "login.failure"
    track_castle_event(Castle::LoginFailed, failed_user)
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
