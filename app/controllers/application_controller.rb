class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include Clearance::Authorization

  helper ActiveSupport::NumberHelper

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_forbidden

  before_action :set_locale
  before_action :reject_null_char_param

  def set_locale
    I18n.locale = user_locale

    # after store current locale
    session[:locale] = params[:locale] if params[:locale]
  rescue I18n::InvalidLocale
    I18n.locale = I18n.default_locale
  end

  rescue_from(ActionController::ParameterMissing) do |e|
    render plain: "Request is missing param '#{e.param}'", status: :bad_request
  end

  def self.http_basic_authenticate_with(**options)
    before_action(options.except(:name, :password, :realm)) do
      raise "Invalid authentication options" unless http_basic_authentication_options_valid?(**options)
    end
    super
  end

  protected

  def http_basic_authentication_options_valid?(**options)
    options[:password].present? && options[:name].present?
  end

  def fastly_expires_in(seconds)
    response.headers["Surrogate-Control"] = "max-age=#{seconds}"
  end

  def set_surrogate_key(*surrogate_keys)
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
  end

  def redirect_to_signin
    response.headers["Cache-Control"] = "private, max-age=0"
    redirect_to sign_in_path, alert: t("please_sign_in")
  end

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id] || params[:id])
    return if @rubygem
    respond_to do |format|
      format.any do
        render plain: t(:this_rubygem_could_not_be_found), status: :not_found
      end
      format.html do
        render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false, formats: [:html]
      end
    end
  end

  def owner?
    @rubygem.owned_by?(current_user)
  end

  def find_versioned_links
    @versioned_links = @rubygem.links(@latest_version)
  end

  def set_page(max_page = Gemcutter::MAX_PAGES)
    sanitize_params
    @page = Gemcutter::DEFAULT_PAGE && return unless params.key?(:page)
    redirect_to_page_with_error && return unless valid_page_param?(max_page)

    @page = params[:page].to_i
  end

  def user_locale
    params[:locale] || session[:locale] || http_head_locale || I18n.default_locale
  end

  def http_head_locale
    http_accept_language.language_region_compatible_from(I18n.available_locales)
  end

  def render_not_found
    respond_to do |format|
      format.html { render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false }
      format.json { render json: { error: t(:not_found) }, status: :not_found }
      format.yaml { render yaml: { error: t(:not_found) }, status: :not_found }
      format.any(:all) { render text: t(:not_found), status: :not_found }
    end
  end

  def render_forbidden
    render plain: "forbidden", status: :forbidden
  end

  def redirect_to_page_with_error
    flash[:error] = t("invalid_page") unless controller_path.starts_with? "api"
    page_params = params.except(:controller, :action, :page)
      .permit(:query, :to, :from, :format, :letter)
      .merge(page: Gemcutter::DEFAULT_PAGE)
    redirect_to url_for(page_params)
  end

  def valid_page_param?(max_page)
    params[:page].respond_to?(:to_i) && params[:page].to_i.between?(Gemcutter::DEFAULT_PAGE, max_page)
  end

  def reject_null_char_param
    render plain: "bad request", status: :bad_request if params.to_s.include?("\\u0000")
  end

  def sanitize_params
    params.delete(:params)
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def password_session_active?
    session[:verification] && session[:verification] > Time.current
  end
end
