class ProfilesController < ApplicationController
  
  before_filter :redirect_to_root, :unless => :signed_in?
  
  def show
    @user = current_user
  end

end
