class Api::V1::VersionsController < Api::BaseController
  respond_to :json, :yaml

  before_action :find_rubygem, only: :show

  def show
    return unless stale?(@rubygem)

    if @rubygem.public_versions.count.nonzero?
      respond_with(@rubygem.public_versions, yamlish: true)
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

    render :json => { "version" => number },
           :callback => params['callback']
  end

  def reverse_dependencies
    versions = Version.reverse_dependencies(params[:id])

    respond_with(versions.map(&:full_name), :yamlish => true)
  end
end
