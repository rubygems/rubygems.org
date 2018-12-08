class RubygemsController < ApplicationController
  include LatestVersion
  before_action :redirect_to_root, only: %i[edit update], unless: :signed_in?
  before_action :set_blacklisted_gem, only: %i[show], if: :blacklisted?
  before_action :find_rubygem, only: %i[edit update show], unless: :blacklisted?
  before_action :latest_version, only: %i[show], unless: :blacklisted?
  before_action :find_versioned_links, only: %i[show], unless: :blacklisted?
  before_action :load_gem, only: %i[edit update]
  before_action :set_page, only: :index

  def index
    respond_to do |format|
      format.html do
        @letter = Rubygem.letterize(params[:letter])
        @gems   = Rubygem.letter(@letter).includes(:latest_version, :gem_download).page(@page)
      end
      format.atom do
        @versions = Version.published(Gemcutter::DEFAULT_PAGINATION)
        render 'versions/feed'
      end
    end
  end

  def show
    if @blacklisted_gem
      render 'blacklisted'
    else
      @versions = @rubygem.public_versions(5)
      if @versions.to_a.any?
        render 'show'
      else
        render 'show_yanked'
      end
    end
  end

  def edit
    flash[:warning] = t('.deprecation_message').html_safe # rubocop:disable Rails/OutputSafety

    @linkset = @rubygem.linkset || @rubygem.build_linkset
  end

  def update
    if @linkset.update(params_linkset)
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
      redirect_to root_path
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
