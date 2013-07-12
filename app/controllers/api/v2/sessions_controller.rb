class SessionsController < Clearance::SessionsController
  ssl_required

  def create

    @user = User.authenticate(params[:session][:who],
                              params[:session][:password])
    if @user.nil?
      flash_failure_after_create
      render :template => 'sessions/new', :status => :unauthorized
    else
      sign_in(@user)
      redirect_back_or(url_after_create)
    end
  end

  private

  def url_after_create
    dashboard_url
  end
end
