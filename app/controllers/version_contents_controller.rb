class VersionContentsController < ApplicationController
  include LatestVersion
  before_action :find_rubygem
  before_action :latest_version_by_slug
  before_action :find_versioned_links

  def index
    @contents = ContentPresenter.new(@rubygem, @latest_version, "")
    return render_not_found if @contents.blank?
  end

  def show
    @contents = ContentPresenter.new(@rubygem, @latest_version, params.require(:path))
    return render_not_found if @contents.blank?

    @entry = @contents.entry
    return render :show if @entry

    render :index
  end
end
