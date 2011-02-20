class Api::V1::Versions::DownloadsController < Api::BaseController
  before_filter :parse_version_id

  # Returns a JSON object containing the number of downloads by day
  # for a particular gem version for 90 days of data.  Output resembles:
  # { 
  #   "2011-02-17":0,
  #   "2011-02-18":0,
  #   "2011-02-19":2,
  #   "2011-02-20":1
  #   ....
  # }
  def index
    if version = Version.find_by_full_name(@name)
      render :json => Download.counts_by_day_for_version(version)
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

  # Returns a JSON object containing the number of downloads by day
  # for a particular gem version for an arbitrary date range. Output resembles:
  # { 
  #   "2011-02-17":0,
  #   "2011-02-18":0,
  #   "2011-02-19":2,
  #   "2011-02-20":1
  #   ....
  # }
  def search
    start, stop = [params[:from], params[:to]].map do |d| 
      Date.parse(d)
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
