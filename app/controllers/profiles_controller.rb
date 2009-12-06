class ProfilesController < ApplicationController
  
  before_filter :redirect_to_root, :unless => :signed_in?
  
  def edit
    @user = current_user
  end
  
  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      @user.unconfirm_email!
      ProfileMailer.deliver_email_reset(@user)
      redirect_to sign_out_path
    end
  end

end
