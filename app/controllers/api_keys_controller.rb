class ApiKeysController < ApplicationController
  def show
    authenticate_or_request_with_http_basic do |username, password|
      @_current_user = User.authenticate(username, password)
      if current_user.email_confirmed
        render :text => current_user.api_key
      end
    end
  end
end
