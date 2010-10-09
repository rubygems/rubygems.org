class VersionsController < ApplicationController
  before_filter :find_rubygem

  def index
    @versions = @rubygem.versions.by_position
  end

  def show
    @latest_version = Version.find_from_slug!(@rubygem.id, params[:id])
    @versions = [@latest_version]
    render "rubygems/show"
  end

  def stats
    @latest_version = @rubygem.versions.most_recent
    @versions = [Version.find_from_slug!(@rubygem.id, params[:id])]
    render "rubygems/stats"
  end

  protected

  def find_rubygem
    @rubygem = Rubygem.find_by_name(params[:rubygem_id])
  end
end
