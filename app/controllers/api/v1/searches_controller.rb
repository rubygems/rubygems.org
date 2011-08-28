class Api::V1::SearchesController < Api::BaseController

  skip_before_filter :verify_authenticity_token
  respond_to :json, :xml

  def show
    @rubygems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
    respond_with(@rubygems) do |format|
      # Convert object to JSON and back before converting to YAML in order to
      # strip the object type (e.g. !ruby/ActiveRecord:Rubygem) from response
      format.yaml { render :text => JSON.load(@rubygems.to_json).to_yaml }
    end
  end

end
