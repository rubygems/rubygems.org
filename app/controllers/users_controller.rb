class UsersController < Clearance::UsersController

  ssl_required

  def user_params
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end
end
