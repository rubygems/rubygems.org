class RubygemsController < ApplicationController
  before_action :redirect_to_root, only: [:edit, :update], unless: :signed_in?
  before_action :set_blacklisted_gem, only: [:show], if: :blacklisted?
  before_action :find_rubygem, only: [:edit, :update, :show], unless: :blacklisted?
  before_action :load_gem, only: [:edit, :update]
  before_action :set_page, only: :index

  def index
    respond_to do |format|
      format.html do
        @letter = Rubygem.letterize(params[:letter])
        @gems   = Rubygem.letter(@letter).includes(:latest_version, :gem_download).paginate(page: @page)
      end
      format.atom do
        @versions = Version.published(20)
        render 'versions/feed'
      end
    end
  end

  def show
    if @blacklisted_gem
      render 'blacklisted'
    else
      @latest_version = @rubygem.versions.most_recent
      @versions       = @rubygem.public_versions(5)
      if @rubygem.public_versions.any?
        render 'show'
      else
        render 'show_yanked'
      end
    end
  end

  def edit
  end

  def update
    if @linkset.update_attributes(params_linkset)
      redirect_to rubygem_path(@rubygem)
      flash[:success] = "Gem links updated."
    else
      render :edit
    end
  end

  protected

  def load_gem
    unless @rubygem.owned_by?(current_user)
      flash[:warning] = "You do not have permission to edit this gem."
      redirect_to root_url
    end

    @linkset = @rubygem.linkset
  end

  private

  def blacklisted?
    (Patterns::GEM_NAME_BLACKLIST.include? params[:id].downcase)
  end

  def set_blacklisted_gem
    @blacklisted_gem = params[:id].downcase
  end

  def params_linkset
    params.require(:linkset).permit(:code, :docs, :wiki, :mail, :bugs)
  end
end
