class Api::V1::WebHooksController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:create]

  before_filter :authenticate_with_api_key, :only => :create
  before_filter :verify_authenticated_user, :only => :create
  
  def create
    url = params[:url]
    gem_name = params[:gem_name]
    unless Rubygem.find_by_name(gem_name)
      return render(:text => "Gem Not Found", :status => 404)
    end
    if WebHook.find(:all, :conditions => {:url => url, :gem_name => gem_name}).empty?
      @web_hook = WebHook.create(:url => url, :gem_name => gem_name)
      render :text => 'success', :status => :created
    else
      render(:text => "WebHook '#{url}' has alredy been registered for Gem '#{gem_name}'", :status => 409)
    end
  end
end
