class VersionContentsController < ApplicationController
  include LatestVersion
  before_action :find_rubygem
  before_action :latest_version_by_slug
  before_action :find_versioned_links

  def index
    @contents = ContentPresenter.new(@rubygem, @latest_version, "")
    @dirs, @files = @latest_version.manifest.ls
    @versions = @rubygem.public_versions
  end

  def show
    @contents = ContentPresenter.new(@rubygem, @latest_version, params.require(:path))
    @entry = @contents.entry
    return render :show if @entry

    @dirs, @files = @latest_version.manifest.ls(@path)
    return render_not_found if @dirs.blank? && @files.blank?
    @versions = @rubygem.public_versions
    render :index
  end
end
