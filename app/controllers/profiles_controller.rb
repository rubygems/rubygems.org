class ProfilesController < ApplicationController

  before_filter :redirect_to_root, :unless => :signed_in?

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      @user.email_changed!
      Mailer.deliver_email_reset @user
      sign_out
      flash[:notice] = "You will receive an email within the next few minutes. " <<
                       "It contains instructions for reconfirming your account with your new email address."
      redirect_to root_path
    else
      render :edit
    end
  end

end
