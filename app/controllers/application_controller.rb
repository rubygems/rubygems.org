class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include Clearance::Authorization

  helper :announcements
  helper ActiveSupport::NumberHelper

  protect_from_forgery only: [:create, :update, :destroy], with: :exception

  before_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  def set_locale
    I18n.locale = user_locale

    # after store current locale
    session[:locale] = params[:locale] if params[:locale]
  rescue I18n::InvalidLocale
    I18n.locale = I18n.default_locale
  end

  rescue_from(ActionController::ParameterMissing) do |e|
    render text: "Request is missing param '#{e.param}'", status: :bad_request
  end

  protected

  def redirect_to_root
    redirect_to root_path
  end

  def authenticate_with_api_key
    api_key = request.headers["Authorization"] || params[:api_key]
    sign_in User.find_by_api_key(api_key)
  end

  def verify_authenticated_user
    return if current_user
    # When in passenger, this forces the whole body to be read before
    # we return a 401 and end the request. We need to do this because
    # otherwise apache is confused why we never read the whole body.
    #
    # This works because request.body is a RewindableInput which will
    # slurp all the socket data into a tempfile, satisfying apache.
    request.body.size if request.body.respond_to? :size
    render text: t(:please_sign_up), status: 401
  end

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id] || params[:id])
    return if @rubygem
    respond_to do |format|
      format.any do
        render text: t(:this_rubygem_could_not_be_found), status: :not_found
      end
      format.html do
        render file: "public/404", status: :not_found, layout: false, formats: [:html]
      end
    end
  end

  def set_page
    @page = [1, params[:page].to_i].max
  end

  def user_locale
    params[:locale] || session[:locale] || http_head_locale || I18n.default_locale
  end

  def http_head_locale
    http_accept_language.language_region_compatible_from(I18n.available_locales)
  end

  def render_404
    respond_to do |format|
      format.html { render file: "public/404", status: :not_found, layout: false }
      format.json { render json: { error: t(:not_found) }, status: :not_found }
      format.yaml { render yaml: { error: t(:not_found) }, status: :not_found }
      format.any(:all) { render text: t(:not_found), status: :not_found }
    end
  end
end
