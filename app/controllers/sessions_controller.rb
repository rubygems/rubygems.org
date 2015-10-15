class SessionsController < Clearance::SessionsController
  def create
    params.require(:session)
    @user = User.authenticate(
      params[:session][:who], params[:session][:password]
    )

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

  def url_after_create
    dashboard_url
  end
end
