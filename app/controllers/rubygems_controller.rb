class RubygemsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate, :only => :create

  def index
    @gems = Rubygem.by_name(:asc)
  end

  def show
    @gem = Rubygem.find(params[:id])
    @current_version = @gem.versions.first
  end

  def create
    temp = Tempfile.new("gem")
    temp.write request.body.read
    temp.flush
    temp.close

    spec = Rubygem.pull_spec(temp.path)
    rubygem = Rubygem.find_or_initialize_by_name(spec.name)
    rubygem.spec = spec
    rubygem.path = temp.path
    rubygem.user = current_user
    rubygem.save
    render :text => "Successfully registered new gem: #{rubygem.with_version}"
  end

  protected
    def authenticate
      authenticate_or_request_with_http_basic do |username, password|
        @_current_user = User.authenticate(username, password)
      end
    end
end
