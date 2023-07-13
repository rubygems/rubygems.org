class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  around_action :rswag

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
    render plain: "This gem could not be found", status: :not_found
  end

  def enqueue_web_hook_jobs(version)
    jobs = version.rubygem.web_hooks.enabled + WebHook.global.enabled
    jobs.each do |job|
      job.fire(
        request.protocol.delete("://"),
        request.host_with_port,
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
    if @rubygem && !@rubygem.mfa_requirement_satisfied_for?(@api_key.user)
      render plain: "Gem requires MFA enabled; You do not have MFA enabled yet.", status: :forbidden
    elsif @api_key.user.mfa_required_not_yet_enabled?
      render_mfa_setup_required_error
    elsif @api_key.user.mfa_required_weak_level_enabled?
      render_mfa_strong_level_required_error
    end
  end

  def response_with_mfa_warning(response)
    message = response
    if @api_key.user.mfa_recommended_not_yet_enabled?
      message += <<~WARN.chomp


        [WARNING] For protection of your account and gems, we encourage you to set up multi-factor authentication \
        at https://rubygems.org/multifactor_auth/new. Your account will be required to have MFA enabled in the future.
      WARN
    elsif @api_key.user.mfa_recommended_weak_level_enabled?
      message += <<~WARN.chomp


        [WARNING] For protection of your account and gems, we encourage you to change your multi-factor authentication \
        level to 'UI and gem signin' or 'UI and API' at https://rubygems.org/settings/edit. \
        Your account will be required to have MFA enabled on one of these levels in the future.
      WARN
    end

    message
  end

  def render_mfa_setup_required_error
    error = <<~ERROR.chomp
      [ERROR] For protection of your account and your gems, you are required to set up multi-factor authentication \
      at https://rubygems.org/multifactor_auth/new.

      Please read our blog post for more details (https://blog.rubygems.org/2022/08/15/requiring-mfa-on-popular-gems.html).
    ERROR
    render_forbidden(error)
  end

  def render_mfa_strong_level_required_error
    error = <<~ERROR.chomp
      [ERROR] For protection of your account and your gems, you are required to change your MFA level to 'UI and gem signin' or 'UI and API' \
      at https://rubygems.org/settings/edit.

      Please read our blog post for more details (https://blog.rubygems.org/2022/08/15/requiring-mfa-on-popular-gems.html).
    ERROR
    render_forbidden(error)
  end

  def authenticate_with_api_key
    params_key = request.headers["Authorization"] || ""
    hashed_key = Digest::SHA256.hexdigest(params_key)
    @api_key   = ApiKey.find_by_hashed_key(hashed_key)
    return render_unauthorized unless @api_key
    set_tags "gemcutter.user.id" => @api_key.user_id, "gemcutter.user.api_key_id" => @api_key.id
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

  def rswag
    f = Rails.root.join("app", "controllers", "api", "v1", "api.yaml")
    schema = OpenAPIParser.load(f, { strict_reference_validation: true, strict_response_validation: true })
    path = request.path
    path = path.delete_suffix(".#{request.format.to_sym}")
    path = path.sub("/api/v1", "")

    ro = schema.request_operation(request.method.downcase.to_sym, path)
    raise "No operation found for #{request.method} #{path}" unless ro

    ro.validate_request_body(request.content_mime_type.to_s, request.request_parameters)
    ro.validate_path_params

    yield.tap do
      ro.validate_response_body(
        OpenAPIParser::RequestOperation::ValidatableResponseBody.new(response.status, deserialized_response_body, response.headers)
      )
    end
  end

  def deserialized_response_body
    case Mime::Type.lookup response.content_type.sub(/^([^,;]*).*/, '\1').strip.downcase
    when Mime::Type.lookup_by_extension(:json)
      JSON.parse(response.body)
    when Mime::Type.lookup_by_extension(:yaml)
      YAML.safe_load(response.body)
    when Mime::Type.lookup("text/plain")
      response.body
    else
      raise "Unknown content type #{response.content_type} (#{response.content_type.sub(/^([^,;]*).*/, '\1')}) in response body: " +
        response.body
    end
  end
end
