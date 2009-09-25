class RubygemsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  before_filter :authenticate_with_api_key, :only => :create
  before_filter :verify_authenticated_user, :only => :create
  before_filter :redirect_to_root, :only => [:edit, :update], :unless => :signed_in?
  before_filter :find_gem, :only => [:edit, :update, :show]
  before_filter :load_gem, :only => [:edit, :update]

  def index
    respond_to do |format|
      format.html do
        params[:letter] = "a" unless params[:letter]
        @gems = Rubygem.name_starts_with(params[:letter]).with_versions.paginate(:page => params[:page])
      end
      format.atom do
        @versions = Version.published(20)
        render 'versions/feed'
      end
    end
  end

  def show
    respond_to do |format|
      format.html do
        @current_version = @rubygem.versions.current
      end
      format.json do
        if @rubygem.try(:hosted?)
          render :json => @rubygem.to_json
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
      redirect_to rubygem_path(@rubygem)
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
    def find_gem
      @rubygem = Rubygem.find_by_name(params[:id])
      if @rubygem.blank?
        respond_to do |format|
          format.html do
            render :file => 'public/404.html'
          end
          format.json do
            render :text => "This rubygem could not be found.", :status => :not_found
          end
        end
      end
    end

    def load_gem
      if !@rubygem.owned_by?(current_user)
        flash[:warning] = "You do not have permission to edit this gem."
        redirect_to root_url
      end

      @linkset = @rubygem.linkset
    end
end
