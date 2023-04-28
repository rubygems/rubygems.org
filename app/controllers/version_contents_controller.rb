class VersionContentsController < ApplicationController
  include LatestVersion
  before_action :find_rubygem
  before_action :latest_version_by_slug
  before_action :find_versioned_links
  before_action :normalize_path, only: :show

  def index
    @path = ""
    @tree = @latest_version.manifest.tree(@path)
    redirect_to rubygem_version_path(@rubygem, @latest_version.slug), flash: { notice: t(".no_files") } if @tree.empty?
  end

  def show
    @entry = @latest_version.manifest.entry(@path)
    return if @entry

    @tree = @latest_version.manifest.tree(@path)
    if @tree.blank?
      render_not_found
    else
      render :index
    end
  end

  def normalize_path
    @path = params[:path].chomp("/")
    @path = "" if @path == "."
    @path = "#{@path}/" if @path.present?
  end
end
