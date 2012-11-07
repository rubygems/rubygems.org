class Api::V1::VersionsController < Api::BaseController
  respond_to :json, :xml, :yaml

  def show
    if rubygem = Rubygem.find_by_name(params[:id]) and rubygem.public_versions.count.nonzero?

      if stale?(rubygem)
        respond_with(rubygem.public_versions, :yamlish => true)
      end
    else
      render :text => "This rubygem could not be found.", :status => 404
    end
  end
end
