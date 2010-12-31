class SessionsController < Clearance::SessionsController
  ssl_required

  def create
    @user = User.authenticate(params[:session][:who],
                              params[:session][:password])
    if @user.nil?
      flash_failure_after_create
      render :template => 'sessions/new', :status => :unauthorized
    else
      if @user.email_confirmed? && !@user.email_reset
        sign_in(@user)
        flash_success_after_create
        redirect_back_or(url_after_create)
      else
        if @user.email_reset
          Mailer.email_reset(@user).deliver
        else
          ClearanceMailer.confirmation(@user).deliver
        end
        flash_notice_after_create
        redirect_to(new_session_url)
      end
    end
  end

  private

  def url_after_create
    dashboard_url
  end
end
