class ApplicationController < ActionController::Base




  include Clearance::Authentication
  helper :all
  protect_from_forgery :only => [:create, :update, :destroy]
  layout 'application'

  def authenticate_with_api_key
    api_key = request.headers["Authorization"] || params[:api_key]
    self.current_user = User.find_by_api_key(api_key)
  end

  def verify_authenticated_user
    if current_user.nil?
      render :text => "Access Denied. Please sign up for an account at http://gemcutter.org", :status => 401
    elsif !current_user.email_confirmed
      render :text => "Access Denied. Please confirm your Gemcutter account.", :status => 403
    end
  end
end

class Clearance::SessionsController < ApplicationController
  include Rf_Check::Checker
  before_filter :rf_check, :only => "create"
end
