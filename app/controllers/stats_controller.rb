class StatsController < ApplicationController
  before_filter :find_gem, :only => :show
  before_filter :ensure_hosted, :only => :show


  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = Download.count
    @most_downloaded     = Rubygem.downloaded(10)
  end

  def show
    if params[:version_id]
      @version  = Version.find_from_slug!(@rubygem.id, params[:version_id])
      @versions = [@version]
    else
      @version  = @rubygem.versions.most_recent
      @versions = @rubygem.versions.limit(5)
    end
  end

  private

  def ensure_hosted
    render :file => 'public/404.html', :status => :not_found if !@rubygem.hosted?
  end
end
