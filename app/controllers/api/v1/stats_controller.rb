class Api::V1::StatsController < Api::BaseController
  def show
    full_name = params[:id].chomp(".json")
    if version = Version.find_by_full_name(full_name)
      render :json => Download.counts_by_day_for_version(version, 89)
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

  def search
    full_name = params[:id].chomp(".json")
    start, stop = [params[:from], params[:to]].map { |d| Date.parse(d) }
    if version = Version.find_by_full_name(full_name)
      render :json => Download.counts_by_day_for_version_in_date_range(version, start, stop) 
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end
end
