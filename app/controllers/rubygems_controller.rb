class RubygemsController < ApplicationController
  before_filter :authenticate, :only => :create

  def index
    @gems = Rubygem.by_name(:asc)
  end

  def show
    @gem = Rubygem.find(params[:id])
    @current_version = @gem.versions.first
  end

  def create
    render :text => "Successfully registered new gem"
  end

  protected
    def authenticate
      authenticate_or_request_with_http_basic do |username, password|
        @_current_user = User.authenticate(username, password)
      end
    end
end
