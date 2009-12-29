class Api::V1::WebHooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  before_filter :authenticate_with_api_key
  before_filter :verify_authenticated_user
  
  def create
    url = params[:url]
    gem_name = params[:gem_name]

    if gem_name != WebHook::ALL_GEMS_PATTERN && !Rubygem.exists?(:name => gem_name)
      render :text   => "This gem could not be found",
						 :status => :not_found
    elsif !WebHook.exists?(:url => url, :gem_name => gem_name)
      WebHook.create(:url => url, :gem_name => gem_name)
      render :text   => "Successfully created webhook for #{gem_name} to #{url}",
					   :status => :created
    else
      render :text   => "A hook for #{url} has already been registered for #{gem_name}",
             :status => 409
    end
  end
end
