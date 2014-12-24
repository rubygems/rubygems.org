class UsersController < Clearance::UsersController

  ssl_required

  def user_params
    params.require(:user).permit(:bio, :email, :handle, :hide_email, :location, :password, :website)
  end
end
