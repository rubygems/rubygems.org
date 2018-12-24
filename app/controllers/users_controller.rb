# frozen_string_literal: true

class UsersController < Clearance::UsersController
  def new
    redirect_to sign_up_path
  end

  def create
    @user = user_from_params
    if @user.save
      Mailer.delay.email_confirmation(@user)
      flash[:notice] = t('.email_sent')
      redirect_back_or url_after_create
    else
      render template: 'users/new'
    end
  end

  def user_params
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end
end
