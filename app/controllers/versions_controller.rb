class VersionsController < ApplicationController
  before_action :find_rubygem

  def index
    @versions = @rubygem.versions.by_position
  end

  def show
    @latest_version  = Version.find_from_slug!(@rubygem.id, params[:id])
    @versions        = @rubygem.public_versions_with_extra_version(@latest_version)
    @versioned_links = @rubygem.links(@latest_version)
    @adoption        = @rubygem.ownership_call
    render "rubygems/show"
  end
end
