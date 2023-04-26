class VersionsController < ApplicationController
  before_action :find_rubygem

  def index
    set_page
    @versions = @rubygem.versions.by_position.page(@page).per(Gemcutter::VERSIONS_PER_PAGE)
  end

  def show
    @latest_version  = @rubygem.find_version_by_slug!(params.require(:id))
    @versions        = @rubygem.public_versions_with_extra_version(@latest_version)
    @versioned_links = @rubygem.links(@latest_version)
    @adoption        = @rubygem.ownership_call
    @on_version_page = true
    render "rubygems/show"
  end
end
