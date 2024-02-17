class VersionsController < ApplicationController
  before_action :find_rubygem

  def index
    set_page
    set_oldest_version_date
    @versions = @rubygem.versions.by_position.page(@page).per(Gemcutter::VERSIONS_PER_PAGE)
  end

  def show
    @latest_version  = @rubygem.find_version_by_slug!(params[:id])
    @versions        = @rubygem.public_versions_with_extra_version(@latest_version)
    @versioned_links = @rubygem.links(@latest_version)
    @on_version_page = true
    render "rubygems/show"
  end

  private

  def set_oldest_version_date
    oldest_created_at = @rubygem.versions.order(:created_at).first
    oldest_built_at = @rubygem.versions.order(:built_at).first
    @oldest_version_date = [oldest_created_at, oldest_built_at].compact.map(&:authored_at).min
  end
end
