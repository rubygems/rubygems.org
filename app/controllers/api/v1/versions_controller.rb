class Api::V1::VersionsController < Api::BaseController
  respond_to :json, :xml, :yaml
  before_filter :find_rubygem

  def show
    if @rubygem.public_versions.count.nonzero?

      if stale?(@rubygem)
        respond_with(@rubygem.public_versions, :yamlish => true)
      end
    else
      render :text => "This rubygem could not be found.", :status => 404
    end
  end

  def latest
    version = @rubygem.versions.latest.first

    render :json => { "version" => version.number }
  end

  def reverse_dependencies
    versions = Version.reverse_dependencies(params[:id])

    respond_with(versions.map(&:full_name), :yamlish => true)
  end
end
