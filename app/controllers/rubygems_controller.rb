class RubygemsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate, :only => :create
  before_filter :redirect_to_root, :only => [:migrate, :mine, :edit, :update], :unless => :signed_in?
  before_filter :load_gem, :only => [:edit, :update]

  def mine
    @gems = current_user.rubygems
  end

  def index
    params[:letter] = "a" unless params[:letter]
    @gems = Rubygem.name_starts_with(params[:letter]).paginate(:page => params[:page])
  end

  def show
    @gem = Rubygem.find(params[:id])
    @current_version = @gem.versions.current
    @current_dependencies = @current_version.dependencies if @current_version
  end

  def edit
  end

  def migrate
    @gem = Rubygem.find(params[:id])

    if @gem.unowned?
      @ownership = Ownership.find_or_create_by_user_id_and_rubygem_id(current_user.id, @gem.id)
    else
      flash[:failure] = "This gem has already been migrated."
      redirect_to rubygem_path(@gem)
    end
  end

  def update
    if @linkset.update_attributes(params[:linkset])
      redirect_to rubygem_path(@gem)
      flash[:success] = "Gem links updated."
    else
      render :edit
    end
  end

  def create
    gemcutter = Gemcutter.new(current_user, request.body)
    gemcutter.process
    render :text => gemcutter.message, :status => gemcutter.code
  end

  protected
    def authenticate
      logger.info request.headers.inspect
      @_current_user = User.find_by_api_key(request.headers["Authorization"])
      if current_user.nil?
        render :text => "Access Denied. Please sign up for an account at http://gemcutter.org", :status => 401
      elsif !current_user.email_confirmed
        render :text => "Access Denied. Please confirm your Gemcutter account.", :status => 403
      end
    end

    def load_gem
      @gem = Rubygem.find(params[:id])

      if !@gem.owned_by?(current_user)
        flash[:warning] = "You do not have permission to edit this gem."
        redirect_to root_url
      end

      @linkset = @gem.linkset
    end
end
