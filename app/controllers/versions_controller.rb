class VersionsController < ApplicationController
  before_action :find_rubygem

  def index
    @versions = @rubygem.versions.with_cve_count.by_position
  end

  def show
    @latest_version  = @rubygem.find_version_by_slug!(params.require(:id))
    @versions        = @rubygem.public_versions_with_extra_version(@latest_version)
    @versioned_links = @rubygem.links(@latest_version)
    @adoption        = @rubygem.ownership_call
    render "rubygems/show"
  end

  def vulnerabilities
    @version = Version.joins(:rubygem).where(rubygems: { name: params[:rubygem_id] }, number: params[:version_id]).first
  end
end
