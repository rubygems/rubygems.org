class RubygemsController < ApplicationController
  before_filter :redirect_to_root, :only => [:edit, :update], :unless => :signed_in?
  before_filter :find_rubygem, :only => [:edit, :update, :show]
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
    @versions       = @rubygem.public_versions(5)
  end

  def edit
  end

  def update
    if params.has_key?(:linkset) && @linkset.update_attributes(params[:linkset])
      redirect_to rubygem_path(@rubygem)
      flash[:success] = "Gem links updated."
    elsif params.has_key? :gittip_enabled
      @rubygem.gittip_enabled = params[:gittip_enabled]
      # FIXME: this is not translation friendly.  does it need to be?
      notice = "Gittip is now #{params[:gittip_enabled] ? 'en' : 'dis'}abled for this gem!"
      redirect_to rubygem_path(@rubygem, notice: notice) if @rubygem.save
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
