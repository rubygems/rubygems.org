class VersionsController < ApplicationController
  before_action :find_rubygem

  def index
    @versions = @rubygem.versions.by_position
  end

  def show
    @latest_version = Version.find_from_slug!(@rubygem.id, params[:id])
    @versions = @rubygem.public_versions_with_extra_version(@latest_version)
    if @rubygem.public_versions.count.zero?
      render "rubygems/show_all_yanked"
    else
      render "rubygems/show"
    end
  end
end
