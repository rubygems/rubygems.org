class Api::V1::RubygemsController < Api::BaseController
  skip_before_action :verify_authenticity_token, :only => [:create, :yank, :unyank]

  before_action :authenticate_with_api_key, :only => [:index, :create, :yank, :unyank]
  before_action :verify_authenticated_user, :only => [:index, :create, :yank, :unyank]
  before_action :find_rubygem,              :only => [:show]
  before_action :find_rubygem_by_name,      :only => [:yank, :unyank]
  before_action :validate_gem_and_version,  :only => [:yank]

  def index
    @rubygems = current_user.rubygems.with_versions
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems, yamlish: true }
    end
  end

  def show
    if @rubygem.hosted? and @rubygem.public_versions.indexed.count.nonzero?
      respond_to do |format|
        format.json { render json: @rubygem }
        format.yaml { render yaml: @rubygem, yamlish: true }
      end
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
    render text: "Unyanking of gems is no longer supported.", status: :gone
  end

  def reverse_dependencies
    names = Rubygem.reverse_dependencies(params[:id]).pluck(:name)

    respond_to do |format|
      format.json { render json: names }
      format.yaml { render yaml: names, yamlish: true }
    end
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
