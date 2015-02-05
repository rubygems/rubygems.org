class StatsController < ApplicationController
  before_action :find_rubygem,  :only => :show
  before_action :ensure_hosted, :only => :show

  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = Download.count
    @most_downloaded     = Rubygem.downloaded(10)
    @most_downloaded_count = @most_downloaded.first.downloads
  end

  private

  def ensure_hosted
    render :file => 'public/404', :status => :not_found if !@rubygem.hosted?
  end
end
