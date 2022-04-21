class RubygemsController < ApplicationController
  include LatestVersion
  before_action :set_blocklisted_gem, only: :show, if: :blocklisted?
  before_action :find_rubygem, only: :show, unless: :blocklisted?
  before_action :latest_version, only: :show, unless: :blocklisted?
  before_action :find_versioned_links, only: :show, unless: :blocklisted?
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
    if @blocklisted_gem
      render "blocklisted"
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

  def blocklisted?
    (Patterns::GEM_NAME_BLOCKLIST.include? params[:id].downcase)
  end

  def set_blocklisted_gem
    @blocklisted_gem = params[:id].downcase
  end

  def gem_params
    params.permit(:letter, :format, :page)
  end
end
