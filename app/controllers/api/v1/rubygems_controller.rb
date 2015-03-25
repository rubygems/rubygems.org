class Api::V1::RubygemsController < Api::BaseController
  skip_before_action :verify_authenticity_token, :only => [:create, :yank, :unyank]

  before_action :authenticate_with_api_key, :only => [:index, :create, :yank, :unyank]
  before_action :verify_authenticated_user, :only => [:index, :create, :yank, :unyank]
  before_action :find_rubygem,              :only => [:show]
  before_action :find_rubygem_by_name,      :only => [:yank, :unyank]
  before_action :validate_gem_and_version,  :only => [:yank, :unyank]

  respond_to :json, :yaml, :on => [:index, :show, :latest, :just_updated]

  def index
    @rubygems = current_user.rubygems.with_versions
    respond_with(@rubygems, :yamlish => true)
  end

  def show
    if @rubygem.hosted? and @rubygem.public_versions.indexed.count.nonzero?
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
      @version.yank!
      StatsD.increment 'yank.success'
      render :text => "Successfully yanked gem: #{@version.to_title}"
    else
      StatsD.increment 'yank.failure'
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

  def reverse_dependencies
    rubygems = Rubygem.reverse_dependencies(params[:id])

    respond_with(rubygems.map(&:name), :yamlish => true)
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
