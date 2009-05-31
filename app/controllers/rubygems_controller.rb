class RubygemsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate, :only => :create
  before_filter :redirect_to_root, :only => [:mine], :unless => :signed_in?

  def new
  end

  def migrate
  end

  def search
  end

  def mine
    @gems = current_user.rubygems.by_name(:asc)
  end

  def index
    @gems = Rubygem.by_name(:asc)
  end

  def show
    @gem = Rubygem.find(params[:id])
  end

  def create
    temp = Tempfile.new("gem")
    temp.write request.body.read
    temp.flush
    temp.close

    spec = Rubygem.pull_spec(temp.path)
    rubygem = Rubygem.find_or_initialize_by_name(spec.name)

    if !rubygem.new_record? && rubygem.user != current_user
      render :text => "You do not have permission to push to this gem.", :status => 403
      return
    end

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
        current_user.email_confirmed
      end
    end
end
