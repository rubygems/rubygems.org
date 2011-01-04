class Api::V1::VersionsController < Api::BaseController
  before_filter :find_gem,                  :only => [:show]

  def show
    if @rubygem.hosted?
      respond_to do |wants|
        wants.any(:json, :all) { render :json => @rubygem.versions.by_position }
        wants.xml  { render :xml  => @rubygem.versions.by_position }
      end
    else
      render :text => "This gem does not exist.", :status => :not_found
    end
  end

end