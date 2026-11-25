# frozen_string_literal: true

class Api::BaseController < ApplicationController
  content_security_policy false

  skip_before_action :verify_authenticity_token
  skip_before_action :set_user_tag
  after_action :skip_session # TODO: verify if this is still needed now that CSP is disabled for API controllers

  rescue_from(Pundit::NotAuthorizedError) do |e|
    render_forbidden(e.policy.error)
  end

  private

  def name_params
    params.permit(:gem_name, :rubygem_name)
  end

  def gem_name
    name_params[:gem_name] || name_params[:rubygem_name]
  end

  def find_rubygem_by_name
    @rubygem = Rubygem.find_by name: gem_name
    return if @rubygem
    render plain: t(:api_gem_not_found), status: :not_found
  end

  def verify_api_key_gem_scope
    return unless @api_key.rubygem && @api_key.rubygem != @rubygem

    render_forbidden t(:api_key_insufficient_scope)
  end

  def verify_with_otp
    otp = request.headers["HTTP_OTP"]
    return if @api_key.mfa_authorized?(otp)
    prompt_text = otp.present? ? t(:otp_incorrect) : t(:otp_missing)
    render plain: prompt_text, status: :unauthorized
  end

  def response_with_mfa_warning(message)
    if @api_key&.mfa_recommended_not_yet_enabled?
      +message << "\n\n" << t("multifactor_auths.api.mfa_recommended_not_yet_enabled").chomp
    elsif @api_key&.mfa_recommended_weak_level_enabled?
      +message << "\n\n" << t("multifactor_auths.api.mfa_recommended_weak_level_enabled").chomp
    else
      message
    end
  end

  def authenticate_with_api_key
    params_key = request.headers["Authorization"] || ""
    hashed_key = Digest::SHA256.hexdigest(params_key)
    @api_key   = ApiKey.unexpired.find_by_hashed_key(hashed_key)
    unless @api_key
      Datadog::Kit::AppSec::Events.track("api_key.authentication.failure") if params_key.present?
      return render_unauthorized
    end
    Current.api_key = @api_key
    set_tags "gemcutter.api_key.owner" => @api_key.owner.to_gid, "gemcutter.user.api_key_id" => @api_key.id
    set_user_identity(@api_key.user) if @api_key.user?
    return reject_api_key("email_not_confirmed", t(:email_not_confirmed)) if @api_key.user&.unconfirmed?
    Current.user = @api_key.user
    reject_api_key("soft_deleted", t(:api_key_soft_deleted)) if @api_key.soft_deleted?
  end

  def reject_api_key(reason, message)
    Datadog::Kit::AppSec::Events.track("api_key.authorization.failure", reason:)
    render_forbidden(message)
  end

  def authenticate_with_password(who, password)
    user = User.authenticate(who, password)
    return user if user

    attempted_user = begin
      login = who.encode(Encoding::UTF_8)
      User.find_by_email(login) || User.find_by(handle: login)
    rescue Encoding::UndefinedConversionError
      nil
    end
    track_password_login_failure(attempted_user, "invalid_credentials", who:)
    nil
  end

  def track_password_login_success(user)
    Datadog::Kit::AppSec::Events::V2.track_user_login_success(
      Digest::SHA256.hexdigest(user.handle || user.email), user.id.to_s
    )
  end

  def track_password_login_failure(user, reason, who: nil)
    login = user ? (user.handle || user.email) : who.to_s
    metadata = { failure_reason: reason }
    metadata[:"usr.id"] = user.id.to_s if user
    Datadog::Kit::AppSec::Events::V2.track_user_login_failure(
      Digest::SHA256.hexdigest(login), user.present?, metadata
    )
  end

  def pundit_user
    @api_key
  end

  def policy_scope(scope)
    super(Array.wrap(scope).prepend(:api))
  end

  def authorize(record, query = nil)
    return if record.nil? # not found is handled by the action
    super(Array.wrap(record).prepend(:api), query)
  end

  def verify_user_api_key
    render_forbidden(t(:api_key_forbidden)) if @api_key.user.blank?
  end

  def render_unauthorized
    render plain: t(:please_sign_up), status: :unauthorized
  end

  def render_forbidden(error = nil)
    error = error.message if error.respond_to?(:message)
    error ||= t(:api_key_forbidden)
    respond_to do |format|
      format.any(:all) { render plain: error, status: :forbidden }
      format.json { render json: { error: }, status: :forbidden }
      format.yaml { render yaml: { error: }, status: :forbidden }
    end
  end

  def skip_session
    request.session_options[:skip] = true
  end

  def deny_shared_cache
    response.headers["Cache-Control"]     = "private, no-store"
    response.headers["Surrogate-Control"] = "max-age=0"
    response.headers["Vary"] = [response.headers["Vary"], "Authorization"].compact_blank.join(", ")
  end

  def render_bad_request(error = "bad request")
    error = error.message if error.is_a?(Exception)
    render json: { error: error.to_s }, status: :bad_request
  end
end
