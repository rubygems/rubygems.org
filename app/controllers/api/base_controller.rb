class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  def gem_name
    params[:gem_name] || params[:rubygem_name]
  end

  def find_rubygem_by_name
    @rubygem  = Rubygem.find_by name: gem_name
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

  def verify_with_otp
    otp = request.headers["HTTP_OTP"]
    return if @api_user.mfa_api_authorized?(otp)
    prompt_text = otp.present? ? t(:otp_incorrect) : t(:otp_missing)
    render plain: prompt_text, status: :unauthorized
  end

  def authenticate_with_api_key
    api_key   = request.headers["Authorization"] || params.permit(:api_key).fetch(:api_key, "")
    @api_user = User.find_by_api_key(api_key)
    render_unauthorized unless @api_user
  end

  def render_unauthorized
    render plain: t(:please_sign_up), status: :unauthorized
  end
end
