class RubygemsController < ApplicationController
  before_filter :redirect_to_root, :only => [:edit, :update], :unless => :signed_in?
  before_filter :find_gem, :only => [:edit, :update, :show, :stats]
  before_filter :load_gem, :only => [:edit, :update]

  def index
    respond_to do |format|
      format.html do
        @letter = Rubygem.letterize(params[:letter])
        @gems   = Rubygem.letter(@letter).paginate(:page => params[:page])
      end
      format.atom do
        @versions = Version.published(20)
        render 'versions/feed'
      end
    end
  end

  def show
    @latest_version = @rubygem.versions.most_recent
  end

  def stats
    @versions = @rubygem.versions.limit(5)
    @latest_version = @versions.first
    if @versions.blank?
      render :file => 'public/404.html', :status => :not_found
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

  protected
    def load_gem
      if !@rubygem.owned_by?(current_user)
        flash[:warning] = "You do not have permission to edit this gem."
        redirect_to root_url
      end

      @linkset = @rubygem.linkset
    end
end
