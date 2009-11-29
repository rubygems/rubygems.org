class Api::V1::WebHooksController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:create]

  before_filter :authenticate_with_api_key, :only => :create
  before_filter :verify_authenticated_user, :only => :create
  
  def create
    unless Rubygem.find_by_name(params[:gem_name])
      return render(:text => "Gem Not Found", :status => 404)
    end
    @web_hook = WebHook.create(:url => params[:url], :gem_name => params[:gem_name])
    render :text => 'success', :status => :created
  end
end
