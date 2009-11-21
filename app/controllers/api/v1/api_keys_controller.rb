class Api::V1::ApiKeysController < ApplicationController
  before_filter :redirect_to_root, :unless => :signed_in?, :only => [:reset]
  
  def show
    authenticate_or_request_with_http_basic do |username, password|
      @_current_user = User.authenticate(username, password)
      if current_user && current_user.email_confirmed
        render :text => current_user.api_key
      else
        false
      end
    end
  end
  
  def reset
    current_user.reset_api_key!
    flash[:notice] = "Your API key has been reset. Don't forget to update your .gemrc file!"
    redirect_to profile_path
  end
end
