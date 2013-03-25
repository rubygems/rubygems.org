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

  def reverse_dependencies
    versions = Version.reverse_dependencies(params[:id])

    if params[:short]
      respond_with(versions.map(&:full_name), :yamlish => true)
    else
      respond_to do |format|
        format.json { render :json => versions.map { |v| v.as_json.merge("full_name" => v.full_name) } }
        format.xml  { render :xml  => versions.map { |v| v.payload.merge("full_name" => v.full_name) } }
        format.yaml { render :text => versions.map { |v| v.payload.merge("full_name" => v.full_name) }.to_yaml }
      end
    end
  end
end
