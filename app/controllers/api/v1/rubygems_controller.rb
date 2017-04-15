class Api::V1::RubygemsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :authenticate_with_api_key, only: [:index, :create]
  before_action :verify_authenticated_user, only: [:index, :create]
  before_action :find_rubygem,              only: [:show, :reverse_dependencies]

  before_action :cors_preflight_check, only: :show
  after_action  :cors_set_access_control_headers, only: :show

  def index
    @rubygems = current_user.rubygems.with_versions
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
    gemcutter = Pusher.new(
      current_user,
      request.body,
      request.protocol.delete("://"),
      request.host_with_port
    )
    gemcutter.process
    render plain: gemcutter.message, status: gemcutter.code
  rescue => e
    Honeybadger.notify(e)
    render plain: "Server error. Please try again.", status: 500
  end

  def reverse_dependencies
    names = begin
      if params[:only] == "development"
        @rubygem.reverse_development_dependencies.pluck(:name)
      elsif params[:only] == "runtime"
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
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET'
    headers['Access-Control-Max-Age'] = '1728000'
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      cors_set_access_control_headers
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'

      render plain: ''
    end
  end
end
