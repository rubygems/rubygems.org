class RubygemsController < ApplicationController
  include LatestVersion
  before_action :set_blacklisted_gem, only: :show, if: :blacklisted?
  before_action :find_rubygem, only: :show, unless: :blacklisted?
  before_action :latest_version, only: :show, unless: :blacklisted?
  before_action :find_versioned_links, only: :show, unless: :blacklisted?
  before_action :set_page, only: :index

  def index
    respond_to do |format|
      format.html do
        @letter = Rubygem.letterize(gem_params[:letter])
        @gems   = Rubygem.letter(@letter).includes(:latest_version, :gem_download).page(@page)
      end
      format.atom do
        @versions = Version.published(Gemcutter::DEFAULT_PAGINATION)
        render "versions/feed"
      end
    end
  end

  def show
    if @blacklisted_gem
      render "blacklisted"
    else
      @versions = @rubygem.public_versions(5)
      @adoption = @rubygem.ownership_call
      if @versions.to_a.any?
        render "show"
      else
        render "show_yanked"
      end
    end
  end

  private

  def blacklisted?
    (Patterns::GEM_NAME_BLACKLIST.include? params[:id].downcase)
  end

  def set_blacklisted_gem
    @blacklisted_gem = params[:id].downcase
  end

  def gem_params
    params.permit(:letter, :format, :page)
  end
end
