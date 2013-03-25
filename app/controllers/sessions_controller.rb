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
      cookies[:ssl] = true
      redirect_back_or(url_after_create)
    end
  end

  def destroy
    cookies.delete(:ssl)
    super
  end

  private

  def url_after_create
    dashboard_url
  end
end
