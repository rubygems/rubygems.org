class SessionsController < Clearance::SessionsController
  include RubyforgeTransfer

  before_filter :rf_check, :only => :create

  def create
    @user = User.authenticate(params[:session][:email],
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
          Mailer.deliver_email_reset(@user)
        else
          ClearanceMailer.deliver_confirmation(@user)
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
