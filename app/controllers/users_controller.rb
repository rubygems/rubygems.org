class UsersController < Clearance::UsersController
  def new
    @user = user_from_params
  end

  def create
    @user = user_from_params
    if @user.save
      Delayed::Job.enqueue EmailConfirmationMailer.new(@user.id)
      flash[:notice] = t(".email_sent")
      redirect_back_or url_after_create
    else
      render template: "users/new"
    end
  end

  private

  def user_params
    params.permit(user: [*User::PERMITTED_ATTRS]).fetch(:user, {})
  end
end
