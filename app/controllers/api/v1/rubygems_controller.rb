class Api::V1::RubygemsController < Api::BaseController
  before_action :authenticate_with_api_key, except: %i[show reverse_dependencies]
  before_action :verify_user_api_key, except: %i[show reverse_dependencies create]
  before_action :find_rubygem, only: %i[show reverse_dependencies]
  before_action :cors_preflight_check, only: :show
  before_action :verify_with_otp, only: %i[create]
  after_action  :cors_set_access_control_headers, only: :show

  def index
    authorize Rubygem, :index?
    return render_forbidden(t(:api_key_insufficient_scope)) unless @api_key.can_index_rubygems?

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

    gemcutter = Pusher.new(@api_key, request.body, request:)
    gemcutter.process
    render plain: response_with_mfa_warning(gemcutter.message), status: gemcutter.code
  rescue Pundit::NotAuthorizedError
    raise # Let the BaseController exception handler render forbidden error
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
