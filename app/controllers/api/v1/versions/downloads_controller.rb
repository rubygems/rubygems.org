class Api::V1::Versions::DownloadsController < Api::BaseController
  respond_to :json, :yaml

  def index
    if version
      respond_with Download.counts_by_day_for_version(version)
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

  def search
    return unless has_required_params?(:from, :to)

    start, stop = [params[:from], params[:to]].map do |d|
      Date.parse(d)
    end

    if version
      respond_with Download.counts_by_day_for_version_in_date_range(version, start, stop)
    else
      render :text => "This rubygem could not be found.", :status => :not_found
    end
  end

  private

  def version
    @version ||= Version.find_by_full_name_and_indexed(params[:version_id], true)
  end
end
