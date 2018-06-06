class SessionsController < Clearance::SessionsController
  before_action :user, only: :create

  def create
    if verifying_otp? && !@user.otp_verified?(session_params[:otp])
      session[:mfa_user] = nil
      login_failure(t('two_factor_auths.incorrect_otp'))
    elsif !verifying_otp? && @user&.mfa_enabled?
      session[:mfa_user] = @user.id
      render 'sessions/otp_prompt'
    else
      do_login
    end
  end

  private

  def user
    @user = if verifying_otp?
              User.where(id: session[:mfa_user]).take
            else
              find_user(session_params)
            end
  end

  def do_login
    sign_in(@user) do |status|
      if status.success?
        login_success
      else
        login_failure(status.failure_message)
      end
    end
  end

  def verifying_otp?
    session_params[:otp].present? && session[:mfa_user].present?
  end

  def login_success
    StatsD.increment 'login.success'
    redirect_back_or(url_after_create)
  end

  def login_failure(message)
    StatsD.increment 'login.failure'
    flash.now.notice = message
    render template: 'sessions/new', status: :unauthorized
  end

  def session_params
    params.require(:session)
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
