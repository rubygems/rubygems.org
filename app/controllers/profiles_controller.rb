class ProfilesController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?, except: :show

  def edit
  end

  def show
    @user           = User.find_by_slug!(params[:id])
    rubygems        = @user.rubygems_downloaded
    @rubygems       = rubygems.slice!(0, 10)
    @extra_rubygems = rubygems
  end

  def update
    if current_user.update_attributes(params_user)
      if current_user.email_reset
        sign_out
        flash[:notice] = "You will receive an email within the next few " \
                         "minutes. It contains instructions for reconfirming " \
                         "your account with your new email address."
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

  def params_user
    params.require(:user).permit(*User::PERMITTED_ATTRS)
  end
end
