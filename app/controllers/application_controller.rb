class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include ApplicationMultifactorMethods
  include TraceTagger

  helper ActiveSupport::NumberHelper

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_forbidden

  before_action :set_locale
  before_action :reject_null_char_param
  before_action :reject_null_char_cookie
  before_action :set_error_context_user
  before_action :set_user_tag
  before_action :set_current_request

  add_flash_types :notice_html

  ###
  # Content security policy override for script-src
  # This is necessary because we use a SHA256 for the importmap script tag
  # because caching behavior of the mostly static pages could mean longer lived nonces
  # being served from cache instead of unique nonces for each request.
  # This ensures that importmap passes CSP and can be cached safely.
  content_security_policy do |policy|
    policy.script_src(
      :self,
      "'sha256-#{Digest::SHA256.base64digest(Rails.application.importmap.to_json(resolver: ApplicationController.helpers))}'",
      "https://secure.gaug.es",
      "https://www.fastly-insights.com"
    )
  end

  def set_locale
    I18n.locale = user_locale

    # after store current locale
    session[:locale] = params[:locale] if params[:locale]
  rescue I18n::InvalidLocale
    I18n.locale = I18n.default_locale
  end

  def set_user_tag
    set_tag "gemcutter.user.id", current_user.id if signed_in?
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

  def cache_expiry_headers(expiry: 60, fastly_expiry: 3600)
    expires_in expiry, public: true
    fastly_expires_in fastly_expiry
  end

  def fastly_expires_in(seconds, stale_while_revalidate: seconds / 2, stale_if_error: seconds / 2)
    response.headers["Surrogate-Control"] = {
      "max-age" => seconds,
      "stale-while-revalidate" => stale_while_revalidate,
      "stale-if-error" => stale_if_error
    }.compact.map { |k, v| "#{k}=#{v}" }.join(", ")
  end

  def set_surrogate_key(*surrogate_keys)
    response.headers["Surrogate-Key"] = surrogate_keys.join(" ")
  end

  def redirect_to_signin
    response.headers["Cache-Control"] = "private, max-age=0"
    redirect_to sign_in_path, alert: t("please_sign_in")
  end

  def redirect_to_root
    redirect_to root_path
  end

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id] || params[:id])
    return if @rubygem
    respond_to do |format|
      format.any do
        render plain: t(:this_rubygem_could_not_be_found), status: :not_found
      end
      format.html do
        render file: Rails.public_path.join("404.html"), status: :not_found, layout: false, formats: [:html]
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
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.json { render json: { error: t(:not_found) }, status: :not_found }
      format.yaml { render yaml: { error: t(:not_found) }, status: :not_found }
      format.any(:all) { render plain: t(:not_found), status: :not_found }
    end
  end

  def render_forbidden(error = "forbidden")
    render plain: error, status: :forbidden
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

  def reject_null_char_cookie
    contains_null_char = cookies.map { |cookie| cookie.join("=") }.join(";").include?("\u0000")
    render plain: "bad request", status: :bad_request if contains_null_char
  end

  def sanitize_params
    params.delete(:params)
  end

  def disable_cache
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def set_error_context_user
    return unless current_user

    Rails.error.set_context(
      user_id: current_user.id,
      user_email: current_user.email
    )
  end

  def set_current_request
    Current.request = request
    Current.user = current_user
  end

  def browser
    Browser.new(request.user_agent)
  end
end
