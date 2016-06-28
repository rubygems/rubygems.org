class UsersController < Clearance::UsersController
  def new
    redirect_to sign_up_path
  end

  def disabled_signup
    flash[:notice] = "Sign up is temporarily disabled."
    redirect_to root_path
  end

  def user_params
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end
end
