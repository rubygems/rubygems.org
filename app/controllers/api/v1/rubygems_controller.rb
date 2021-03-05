class Api::V1::RubygemsController < Api::BaseController
  before_action :authenticate_with_api_key, except: %i[show reverse_dependencies]
  before_action :find_rubygem,              only: %i[show reverse_dependencies]
  before_action :cors_preflight_check, only: :show
  before_action :verify_with_otp, only: %i[create]
  after_action  :cors_set_access_control_headers, only: :show

  def index
    return render_forbidden unless @api_key.can_index_rubygems?

    @rubygems = @api_key.user.rubygems.with_versions
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end

  def show
    if @rubygem.hosted? && @rubygem.public_versions.indexed.count.nonzero?
      respond_to do |format|
        format.json { render json: @rubygem }
        format.yaml { render yaml: @rubygem }
      end
    else
      render plain: t(:this_rubygem_could_not_be_found), status: :not_found
    end
  end

  def create
    return render_api_key_forbidden unless @api_key.can_push_rubygem?

    gemcutter = Pusher.new(@api_key.user, request.body, request.remote_ip)
    enqueue_web_hook_jobs(gemcutter.version) if gemcutter.process
    render plain: gemcutter.message, status: gemcutter.code
  rescue => e
    Honeybadger.notify(e)
    render plain: "Server error. Please try again.", status: :internal_server_error
  end

  def reverse_dependencies
    names = begin
      case params[:only]
      when "development"
        @rubygem.reverse_development_dependencies.pluck(:name)
      when "runtime"
        @rubygem.reverse_runtime_dependencies.pluck(:name)
      else
        @rubygem.reverse_dependencies.pluck(:name)
      end
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
