class Api::V1::RubygemsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :authenticate_with_api_key, only: [:index, :create]
  before_action :verify_authenticated_user, only: [:index, :create]
  before_action :find_rubygem,              only: [:show]

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
      render text: t(:this_rubygem_could_not_be_found), status: :not_found
    end
  end

  def create
    gemcutter = Pusher.new(
      current_user,
      request.body,
      request.protocol.delete("://"),
      request.host_with_port)
    gemcutter.process
    render text: gemcutter.message, status: gemcutter.code
  rescue => e
    Honeybadger.notify(e)
    render text: "Server error. Please try again.", status: 500
  end

  def reverse_dependencies
    names = begin
      if params[:only] == "development"
        Rubygem.reverse_development_dependencies(params[:id]).pluck(:name)
      elsif params[:only] == "runtime"
        Rubygem.reverse_runtime_dependencies(params[:id]).pluck(:name)
      else
        Rubygem.reverse_dependencies(params[:id]).pluck(:name)
      end
    end

    respond_to do |format|
      format.json { render json: names }
      format.yaml { render yaml: names }
    end
  end
end
