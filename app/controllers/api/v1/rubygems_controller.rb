class Api::V1::RubygemsController < Api::BaseController
  before_action :authenticate_with_api_key, except: %i[show reverse_dependencies]
  before_action :verify_user_api_key, except: %i[show reverse_dependencies create]
  before_action :find_rubygem, only: %i[show reverse_dependencies]
  before_action :cors_preflight_check, only: :show
  before_action :verify_with_otp, only: %i[create]
  after_action  :cors_set_access_control_headers, only: :show

  def index
    authorize Rubygem, :index?
    @rubygems = @api_key.user.rubygems.with_versions
      .preload(:linkset, :gem_download, most_recent_version: { dependencies: :rubygem, gem_download: nil })
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end

  def show
    cache_expiry_headers
    set_surrogate_key "gem/#{@rubygem.name}"

    if @rubygem.hosted? && @rubygem.public_versions.indexed.present?
      respond_to do |format|
        format.json { render json: @rubygem }
        format.yaml { render yaml: @rubygem }
      end
    else
      render plain: t(:this_rubygem_could_not_be_found), status: :not_found
    end
  end

  def create
    authorize Rubygem, :create?
    return render_forbidden(t(:api_key_insufficient_scope)) unless @api_key.can_push_rubygem?

    gem_body = attestations = nil
    if %w[multipart/form-data multipart/mixed].include?(request.media_type)
      gem_body = params.expect(:gem)
      return render_bad_request("gem is not a file upload") unless gem_body.is_a?(ActionDispatch::Http::UploadedFile)
      return render_bad_request("missing attestations") unless (attestations = params[:attestations]).is_a?(String)
      attestations = ActiveSupport::JSON.decode(attestations)
      return render_bad_request("attestations must be an array, is #{attestations.class}") unless attestations.is_a?(Array)
      attestations = attestations&.as_json
    else
      gem_body = request.body
    end

    gemcutter = Pusher.new(@api_key, gem_body, request:, attestations:)
    gemcutter.process
    render plain: response_with_mfa_warning(gemcutter.message), status: gemcutter.code
  rescue Pundit::NotAuthorizedError
    raise # allow rescue_from in base_controller to handle this
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    render plain: "Server error. Please try again.", status: :internal_server_error
  end

  def reverse_dependencies
    cache_expiry_headers(fastly_expiry: 30)

    names = case params[:only]
            when "development"
              @rubygem.reverse_development_dependencies.pluck(:name)
            when "runtime"
              @rubygem.reverse_runtime_dependencies.pluck(:name)
            else
              @rubygem.reverse_dependencies.pluck(:name)
            end

    respond_to do |format|
      format.json { render json: names }
      format.yaml { render yaml: names }
    end
  end

  private

  def cors_set_access_control_headers
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "GET"
    headers["Access-Control-Max-Age"] = "1728000"
  end

  def cors_preflight_check
    return unless request.method == "OPTIONS"

    cors_set_access_control_headers
    headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-Prototype-Version"
    render plain: ""
  end
end
