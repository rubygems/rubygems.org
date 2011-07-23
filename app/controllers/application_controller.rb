class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include SimpleSSLRequirement

  helper :announcements

  protect_from_forgery :only => [:create, :update, :destroy]

  ssl_required :if => :signed_in?

  def authenticate_with_api_key
    api_key = request.headers["Authorization"] || params[:api_key]
    self.current_user = User.find_by_api_key(api_key)
  end

  def verify_authenticated_user
    if current_user.nil?
      render :text => t(:please_sign_up), :status => 401
    elsif !current_user.email_confirmed
      render :text => t(:please_confirm), :status => 403
    end
  end

  def find_gem
    @rubygem = Rubygem.find_by_name(params[:id] || params[:rubygem_id])
    if @rubygem.blank?
      respond_to do |format|
        format.html do
          render :file => "public/404.html", :status => :not_found, :layout => false
        end
        format.json do
          render :text => "This rubygem could not be found.", :status => :not_found
        end
      end
    end
  end

  def find_gem_by_name
    @url      = params[:url]
    @gem_name = params[:gem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    if @rubygem.nil? && @gem_name != WebHook::GLOBAL_PATTERN
      render :text   => "This gem could not be found",
             :status => :not_found
    end
  end
end
