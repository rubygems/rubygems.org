class ProfilesController < ApplicationController
  before_filter :redirect_to_root, :unless => :signed_in?, :except => :show

  def edit
  end

  def show
    @user           = User.find_by_slug!(params[:id])
    rubygems        = @user.rubygems_downloaded
    @rubygems       = rubygems.slice!(0, 10)
    @extra_rubygems = rubygems
  end

  def update
    if current_user.update_attributes(user_params)
      if current_user.email_reset
        sign_out
        flash[:notice] = "You will receive an email within the next few minutes. " <<
                         "It contains instructions for reconfirming your account with your new email address."
        redirect_to root_path
      else
        flash[:notice] = "Your profile was updated."
        redirect_to edit_profile_path
      end
    else
      render :edit
    end
  end
  
  private 
  
  def user_params
    params.require(:user).permit(
      :bio, 
      :email, 
      :handle, 
      :hide_email, 
      :location, 
      :password, 
      :website, 
      :gittip_username,
    )
  end
end
