class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  private

  def gem_name
    params[:gem_name] || params[:rubygem_name]
  end

  def find_rubygem_by_name
    @rubygem = Rubygem.find_by name: gem_name
    return if @rubygem
    render plain: "This gem could not be found", status: :not_found
  end

  def enqueue_web_hook_jobs(version)
    jobs = version.rubygem.web_hooks + WebHook.global
    jobs.each do |job|
      job.fire(
        request.protocol.delete("://"),
        request.host_with_port,
        version.rubygem,
        version
      )
    end
  end

  def verify_api_key_gem_scope
    return unless @api_key.rubygem && @api_key.rubygem != @rubygem

    render plain: "This API key cannot perform the specified action on this gem.", status: :forbidden
  end

  def verify_with_otp
    otp = request.headers["HTTP_OTP"]
    return if @api_key.mfa_authorized?(otp)
    prompt_text = otp.present? ? t(:otp_incorrect) : t(:otp_missing)
    render plain: prompt_text, status: :unauthorized
  end

  def verify_mfa_requirement
    return if @rubygem.mfa_requirement_satisfied_for?(@api_key.user)
    render plain: "Gem requires MFA enabled; You do not have MFA enabled yet.", status: :forbidden
  end

  def authenticate_with_api_key
    params_key = request.headers["Authorization"] || ""
    hashed_key = Digest::SHA256.hexdigest(params_key)
    @api_key   = ApiKey.find_by_hashed_key(hashed_key)
    return render_unauthorized unless @api_key
    render_soft_deleted_api_key if @api_key.soft_deleted?
  end

  def render_unauthorized
    render plain: t(:please_sign_up), status: :unauthorized
  end

  def render_api_key_forbidden
    respond_to do |format|
      format.any(:all) { render plain: t(:api_key_forbidden), status: :forbidden }
      format.json { render json: { error: t(:api_key_forbidden) }, status: :forbidden }
      format.yaml { render yaml: { error: t(:api_key_forbidden) }, status: :forbidden }
    end
  end

  def render_soft_deleted_api_key
    render plain: "An invalid API key cannot be used. Please delete it and create a new one.", status: :forbidden
  end
end
