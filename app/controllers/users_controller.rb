class UsersController < Clearance::UsersController
  ssl_required

  def new
    redirect_to sign_up_path
  end

  def user_params
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end
end
