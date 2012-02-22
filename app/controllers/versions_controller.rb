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

end
