class Api::V1::RubygemsController < Api::BaseController
  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :authenticate_with_api_key, only: [:index, :create]
  before_action :verify_authenticated_user, only: [:index, :create]
  before_action :find_rubygem,              only: [:show]

  def index
    @rubygems = current_user.rubygems.with_versions
    render_as @rubygems
  end

  def show
    if @rubygem.hosted? && @rubygem.public_versions.indexed.count.nonzero?
      render_as @rubygem
    else
      render text: "This gem does not exist.", status: :not_found
    end
  end

  def create
    gemcutter = Pusher.new(current_user, request.body, request.protocol.delete("://"), request.host_with_port)
    gemcutter.process
    render text: gemcutter.message, status: gemcutter.code
  end

  def reverse_dependencies
    names = Rubygem.reverse_dependencies(params[:id]).pluck(:name)

    render_as names
  end
end
