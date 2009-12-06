class ProfilesController < ApplicationController
  
  before_filter :redirect_to_root, :unless => :signed_in?
  
  def edit
    @user = current_user
  end
  
  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      @user.unconfirm_email!
      ::ClearanceMailer.deliver_confirmation @user
      redirect_to sign_out_path
    else
      render :edit
    end
  end

end
