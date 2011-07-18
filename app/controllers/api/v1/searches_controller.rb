class Api::V1::SearchesController < Api::BaseController

  skip_before_filter :verify_authenticity_token

  def show
    @gems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
    respond_to do |format|
      format.json { render :json => @gems }
      format.xml  { render :xml  => @gems }
      # Convert object to JSON and back before converting to YAML in order to
      # strip the object type (e.g. !ruby/ActiveRecord:Rubygem) from response
      format.yaml { render :text => JSON.load(@gems.to_json).to_yaml }
    end
  end

end
