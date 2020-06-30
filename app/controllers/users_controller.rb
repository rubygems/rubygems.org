class UsersController < Clearance::UsersController
  def new
    redirect_to sign_up_path
  end

  def create
    @user = user_from_params
    if @user.save
      Mailer.delay.email_confirmation(@user)
      flash[:notice] = t(".email_sent")
      Delayed::Job.enqueue(
        Castle::RegistrationSucceeded.new(@user, castle_context), priority: PRIORITIES[:stats]
      )
      redirect_back_or url_after_create
    else
      Delayed::Job.enqueue(
        Castle::RegistrationFailed.new(@user, castle_context), priority: PRIORITIES[:stats]
      )
      render template: "users/new"
    end
  end

  private

  def castle_context
    ::Castle::Client.to_context(request)
  end

  def user_params
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end
end
