class SessionsController < Clearance::SessionsController
  def create
    @user = find_user(params.require(:session))

    sign_in(@user) do |status|
      if status.success?
        StatsD.increment 'login.success'
        redirect_back_or(url_after_create)
      else
        StatsD.increment 'login.failure'
        flash.now.notice = status.failure_message
        render template: 'sessions/new', status: :unauthorized
      end
    end
  end

  private

  def find_user(session)
    who = session[:who].is_a?(String) && session.fetch(:who)
    password = session[:password].is_a?(String) && session.fetch(:password)

    User.authenticate(who, password) if who && password
  end

  def url_after_create
    dashboard_url
  end
end
