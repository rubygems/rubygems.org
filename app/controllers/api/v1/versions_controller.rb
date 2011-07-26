class Api::V1::VersionsController < Api::BaseController
  def show
    if rubygem = Rubygem.find_by_name(params[:id])
      respond_to do |format|
        format.json { render :json => rubygem.public_versions }
        format.xml  { render :xml  => rubygem.public_versions }
        format.yaml { render :text => rubygem.public_versions.to_yaml }
      end
    else
      render :text => "This rubygem could not be found.", :status => 404
    end
  end
end
