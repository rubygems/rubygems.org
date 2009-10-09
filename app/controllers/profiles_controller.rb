class ProfilesController < ApplicationController
  
  before_filter :redirect_to_root, :unless => :signed_in?
  
  def edit
    @user = current_user
  end

end
