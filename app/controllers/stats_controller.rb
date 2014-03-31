class StatsController < ApplicationController
  before_filter :find_rubygem,  :only => :show
  before_filter :ensure_hosted, :only => :show

  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = Download.count
    @most_downloaded     = Rubygem.downloaded(10)
  end

  def show
    if params_version_id
      @subtitle        = I18n.t('stats.show.for', :for => params_version_id)
      @version         = Version.find_from_slug!(@rubygem.id, params_version_id)
      @versions        = [@version]
      @downloads_today = Download.today(@version)
      @rank            = Download.rank(@version)
    else
      @subtitle        = I18n.t('stats.show.overview')
      @version         = @rubygem.versions.most_recent
      @versions        = @rubygem.versions.indexed.by_built_at.limit(5)
      @downloads_today = Download.today(@rubygem.versions)
      @rank            = Download.highest_rank(@rubygem.versions)
    end

    @downloads_total = @version.rubygem.downloads
    @cardinality     = Download.cardinality
  end

  private

  def ensure_hosted
    render :file => 'public/404', :status => :not_found if !@rubygem.hosted?
  end
  
  def params_version_id
    params.permit(:version_id)[:version_id]
  end
end
