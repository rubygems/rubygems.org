class RubygemsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate_with_api_key, :only => :create
  before_filter :redirect_to_root, :only => [:mine, :edit, :update], :unless => :signed_in?
  before_filter :load_gem, :only => [:edit, :update]

  def mine
    @gems = current_user.rubygems
  end

  def index
    params[:letter] = "a" unless params[:letter]
    @gems = Rubygem.name_starts_with(params[:letter]).paginate(:page => params[:page])
  end

  def show
    respond_to do |format|
      format.html do
        @gem = Rubygem.find(params[:id])
        @current_version = @gem.versions.current
        @current_dependencies = @current_version.dependencies if @current_version
      end
      format.json do
        @gem = Rubygem.super_find(params[:id])
        if @gem.hosted?
          render :json => @gem.to_json
        else
          render :json => "Not hosted here.", :status => :not_found
        end
      end
    end
  end

  def edit
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

    def load_gem
      @gem = Rubygem.find(params[:id])

      if !@gem.owned_by?(current_user)
        flash[:warning] = "You do not have permission to edit this gem."
        redirect_to root_url
      end

      @linkset = @gem.linkset
    end
end
