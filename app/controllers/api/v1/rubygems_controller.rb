class Api::V1::RubygemsController < Api::BaseController
  skip_before_filter :verify_authenticity_token, :only => [:create, :yank, :unyank]

  before_filter :authenticate_with_api_key, :only => [:index, :create, :yank, :unyank]
  before_filter :verify_authenticated_user, :only => [:index, :create, :yank, :unyank]
  before_filter :find_gem,                  :only => [:show]
  before_filter :find_gem_by_name,          :only => [:yank, :unyank]
  before_filter :validate_gem_and_version,  :only => [:yank, :unyank]

  respond_to :json, :xml, :yaml, :on => [:index, :show, :latest, :just_updated]

  def index
    @rubygems = current_user.rubygems.with_versions
    respond_with(@rubygems, :yamlish => true)
  end

  def show
    if @rubygem.hosted?
      respond_with(@rubygem, :yamlish => true)
    else
      render :text => "This gem does not exist.", :status => :not_found
    end
  end

  def create
    gemcutter = Pusher.new(current_user, request.body, request.host_with_port)
    gemcutter.process
    render :text => gemcutter.message, :status => gemcutter.code
  end

  def yank
    if @version.indexed?
      @rubygem.yank!(@version)
      render :text => "Successfully yanked gem: #{@version.to_title}"
    else
      render :text => "The version #{params[:version]} has already been yanked.", :status => :unprocessable_entity
    end
  end

  def unyank
    if !@version.indexed?
      @version.unyank!
      render :text => "Successfully unyanked gem: #{@version.to_title}"
    else
      render :text => "The version #{params[:version]} is already indexed.", :status => :unprocessable_entity
    end
  end

  def latest
    @rubygems = Rubygem.latest(50)
    respond_with(@rubygems, :yamlish => true)
  end

  def just_updated
    @rubygems = Version.just_updated(50).map(&:rubygem)
    respond_with(@rubygems, :yamlish => true)
  end

  private

  def validate_gem_and_version
    if !@rubygem.hosted?
      render :text => "This gem does not exist.", :status => :not_found
    elsif !@rubygem.owned_by?(current_user)
      render :text => "You do not have permission to yank this gem.", :status => :forbidden
    else
      begin
        slug = params[:platform].blank? ? params[:version] : "#{params[:version]}-#{params[:platform]}"
        @version = Version.find_from_slug!(@rubygem, slug)
      rescue ActiveRecord::RecordNotFound
        render :text => "The version #{params[:version]} does not exist.", :status => :not_found
      end
    end
  end
end
