class Api::V1::VersionsController < Api::BaseController
  before_action :find_rubygem, only: :show

  def show
    return unless stale?(@rubygem)

    if @rubygem.public_versions.count.nonzero?
      respond_to do |format|
        format.json { render json: @rubygem.public_versions }
        format.yaml { render yaml: @rubygem.public_versions, yamlish: true }
      end
    else
      render text: "This rubygem could not be found.", status: 404
    end
  end

  def latest
    rg = Rubygem.find_by_name params[:id]

    if rg.blank?
      number = "unknown"
    else
      if ver = rg.versions.latest.first
        number = ver.number
      else
        number = "unknown"
      end
    end

    render json: { "version" => number }, callback: params['callback']
  end

  def reverse_dependencies
    versions = Version.reverse_dependencies(params[:id])
    names = versions.map(&:full_name)
    respond_to do |format|
      format.json { render json: names }
      format.yaml { render yaml: names, yamlish: true }
    end
  end
end
