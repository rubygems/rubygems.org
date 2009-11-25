class Api::V1::WebHooksController < ApplicationController
  # before_filter :authenticate_with_api_key, :only => :create
  # before_filter :verify_authenticated_user, :only => :create
  class WebHook
    def self.create(*args)
     "not nil" 
    end
  end
  def create
    @web_hook = WebHook.create(params[:web_hook])
    head :created
  end
end
