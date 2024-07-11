class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  after_action :skip_session

  rescue_from(Pundit::NotAuthorizedError) { |_| render_forbidden(t(:api_key_forbidden)) }

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

  def verify_mfa_requirement
    if @rubygem && !@rubygem.mfa_requirement_satisfied_for?(@api_key.user)
      render_forbidden t("multifactor_auths.api.mfa_required")
    elsif @api_key.mfa_required_not_yet_enabled?
      render_forbidden t("multifactor_auths.api.mfa_required_not_yet_enabled").chomp
    elsif @api_key.mfa_required_weak_level_enabled?
      render_forbidden t("multifactor_auths.api.mfa_required_weak_level_enabled").chomp
    end
  end

  def response_with_mfa_warning(message)
    if @api_key.mfa_recommended_not_yet_enabled?
      +message << "\n\n" << t("multifactor_auths.api.mfa_recommended_not_yet_enabled").chomp
    elsif @api_key.mfa_recommended_weak_level_enabled?
      +message << "\n\n" << t("multifactor_auths.api.mfa_recommended_weak_level_enabled").chomp
    else
      message
    end
  end

  def authenticate_with_api_key
    params_key = request.headers["Authorization"] || ""
    hashed_key = Digest::SHA256.hexdigest(params_key)
    @api_key   = ApiKey.unexpired.find_by_hashed_key(hashed_key)
    return render_unauthorized unless @api_key
    set_tags "gemcutter.api_key.owner" => @api_key.owner.to_gid, "gemcutter.user.api_key_id" => @api_key.id
    Current.user = @api_key.user
    render_forbidden(t(:api_key_soft_deleted)) if @api_key.soft_deleted?
  end

  def pundit_user
    @api_key
  end

  def policy_scope(scope)
    super(Array.wrap(scope).prepend(:api))
  end

  def authorize(record, query = nil)
    super(Array.wrap(record).prepend(:api), query)
  end

  def verify_user_api_key
    render_forbidden(t(:api_key_forbidden)) if @api_key.user.blank?
  end

  def render_unauthorized
    render plain: t(:please_sign_up), status: :unauthorized
  end

  def render_forbidden(error = t(:api_key_forbidden))
    respond_to do |format|
      format.any(:all) { render plain: error, status: :forbidden }
      format.json { render json: { error: }, status: :forbidden }
      format.yaml { render yaml: { error: }, status: :forbidden }
    end
  end

  def skip_session
    request.session_options[:skip] = true
  end

  def render_bad_request(error = "bad request")
    error = error.message if error.is_a?(Exception)
    render json: { error: error.to_s }, status: :bad_request
  end

  def owner?
    @api_key.owner.owns_gem?(@rubygem)
  end
end
