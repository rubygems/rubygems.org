class RubygemsController < ApplicationController
  include LatestVersion
  before_action :set_reserved_gem, only: :show, if: :reserved?
  before_action :find_rubygem, only: :show, unless: :reserved?
  before_action :latest_version, only: :show, unless: :reserved?
  before_action :find_versioned_links, only: :show, unless: :reserved?
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
    if @reserved_gem
      render "reserved"
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

  def reserved?
    (Patterns::GEM_NAME_RESERVED_LIST.include? params[:id].downcase)
  end

  def set_reserved_gem
    @reserved_gem = params[:id].downcase
  end

  def gem_params
    params.permit(:letter, :format, :page)
  end
end
