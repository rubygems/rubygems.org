class StatsController < ApplicationController
  before_filter :find_rubygem,  :only => :show
  before_filter :ensure_hosted, :only => :show

  def index
    @number_of_gems      = Rubygem.total_count
    @number_of_users     = User.count
    @number_of_downloads = Download.count
    @most_downloaded     = Rubygem.downloaded(10)
  end

  private

  def ensure_hosted
    render :file => 'public/404', :status => :not_found if !@rubygem.hosted?
  end
end
