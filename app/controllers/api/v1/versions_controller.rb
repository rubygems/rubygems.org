class Api::V1::VersionsController < Api::BaseController
  before_action :find_rubygem, only: :show

  def show
    return unless stale?(@rubygem)

    if @rubygem.public_versions.count.nonzero?
      respond_to do |format|
        format.json { render json: @rubygem.public_versions }
        format.yaml { render yaml: @rubygem.public_versions }
      end
    else
      render text: "This rubygem could not be found.", status: 404
    end
  end

  def latest
    rg = Rubygem.find_by_name params[:id]
    if rg.present? && ver = rg.versions.most_recent
      number = ver.number
    end

    render json: { "version" => number || "unknown" }, callback: params['callback']
  end

  def reverse_dependencies
    names = Version.reverse_dependencies(params[:id]).pluck(:full_name)
    respond_to do |format|
      format.json { render json: names }
      format.yaml { render yaml: names }
    end
  end
end
