class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include Clearance::Authorization
  include SimpleSSLRequirement

  helper :announcements
  protect_from_forgery :only => [:create, :update, :destroy]
  ssl_required :if => :ssl_required?

  before_filter :set_locale, :auto_login

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def auto_login
    unless current_user
      if cookies[:auto_login]
        # Sign them in using the unique `remember_token` saved
        # to the `auto_login` cookie when they first logged in.
        sign_in(User.find_by_remember_token(cookies[:auto_login]))
      end
    end
  end

  # Adding this keeps the user on the same locale, but currently breaks a lot of tests testing for specific urls.
  # def default_url_options(options={})
      # { :locale => I18n.locale }
  # end

  protected

  def redirect_to_root
    redirect_to root_path
  end

  def authenticate_with_api_key
    api_key = request.headers["Authorization"] || params[:api_key]
    sign_in User.find_by_api_key(api_key)
  end

  def verify_authenticated_user
    if current_user.nil?
      # When in passenger, this forces the whole body to be read before
      # we return a 401 and end the request. We need to do this because
      # otherwise apache is confused why we never read the whole body.
      #
      # This works because request.body is a RewindableInput which will
      # slurp all the socket data into a tempfile, satisfying apache.
      request.body.size if request.body.respond_to? :size
      render :text => t(:please_sign_up), :status => 401
    end
  end

  def ssl_required?
    cookies[:ssl]
  end

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id] || params[:id])
    if @rubygem.blank?
      respond_to do |format|
        format.any do
          render :text => "This rubygem could not be found.", :status => :not_found
        end
        format.html do
          render :file => "public/404", :status => :not_found, :layout => false, :formats => [:html]
        end
      end
    end
  end

  def find_rubygem_by_name
    @url      = params[:url]
    @gem_name = params[:gem_name]
    @rubygem  = Rubygem.find_by_name(@gem_name)
    if @rubygem.nil? && @gem_name != WebHook::GLOBAL_PATTERN
      render :text   => "This gem could not be found",
             :status => :not_found
    end
  end
end
