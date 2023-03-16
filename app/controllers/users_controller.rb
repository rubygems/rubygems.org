class UsersController < Clearance::UsersController
  def new
    @user = user_from_params
  end

  def create
    @user = user_from_params
    if @user.save
      Mailer.email_confirmation(@user).deliver_later
      flash[:notice] = t(".email_sent")
      redirect_back_or url_after_create
    else
      render template: "users/new"
    end
  end

  private

  def user_params
    params.permit(user: Array(User::PERMITTED_ATTRS)).fetch(:user, {})
  end
end
