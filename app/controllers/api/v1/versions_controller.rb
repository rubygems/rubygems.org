class Api::V1::VersionsController < Api::BaseController
  before_action :find_rubygem, only: :show

  def show
    return unless stale?(@rubygem)

    if @rubygem.public_versions.count.nonzero?
      render_as @rubygem.public_versions
    else
      render text: "This rubygem could not be found.", status: 404
    end
  end

  def latest
    rubygem = Rubygem.find_by_name(params[:id])
    version = nil
    if rubygem && rubygem.public_versions.indexed.count.nonzero?
      version = rubygem.versions.most_recent
    end
    number = version.number if version
    render json: { "version" => number || "unknown" }, callback: params['callback']
  end

  def reverse_dependencies
    names = Version.reverse_dependencies(params[:id]).pluck(:full_name)
    render_as names
  end
end
