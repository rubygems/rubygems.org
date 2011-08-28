class Api::V1::VersionsController < Api::BaseController
  respond_to :json, :xml

  def show
    if rubygem = Rubygem.find_by_name(params[:id])
      respond_with(rubygem.public_versions) do |format|
        # Convert object to JSON and back before converting to YAML in order to
        # strip the object type (e.g. !ruby/ActiveRecord:Rubygem) from response
        format.yaml { render :text => JSON.load(rubygem.public_versions.to_json).to_yaml }
      end
    else
      render :text => "This rubygem could not be found.", :status => 404
    end
  end
end
