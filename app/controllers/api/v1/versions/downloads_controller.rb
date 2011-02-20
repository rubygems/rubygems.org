class Api::V1::Versions::DownloadsController < Api::BaseController
  before_filter :parse_version_id

  def index
    if version = Version.find_by_full_name(@name)
      render :json => Download.counts_by_day_for_version(version, 89)
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

  def search
    start, stop = [params[:from], params[:to]].map do |d| 
      Date.parse(d)
    end

    if stop - start >= 90
      render :text => "Date ranges for searches may not exceed 90 days", :status => 403
      return
    end

    if version = Version.find_by_full_name(@name)
      render :json => Download.counts_by_day_for_version_in_date_range(version, start, stop) 
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

  protected

  def parse_version_id
    @name = params[:version_id].chomp(".json")
  end
end
