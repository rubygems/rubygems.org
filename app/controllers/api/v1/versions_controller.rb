class Api::V1::VersionsController < Api::BaseController
  def show
    if rubygem = Rubygem.find_by_name(params[:id])
      respond_to do |format|
        format.json { render :json => rubygem.public_versions }
        format.xml  { render :xml  => rubygem.public_versions }
        # Convert object to JSON and back before converting to YAML in order to
        # strip the object type (e.g. !ruby/ActiveRecord:Rubygem) from response
        format.yaml { render :text => JSON.load(rubygem.public_versions.to_json).to_yaml }
      end
    else
      render :text => "This rubygem could not be found.", :status => 404
    end
  end
end
