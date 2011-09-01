class Api::V1::SearchesController < Api::BaseController

  skip_before_filter :verify_authenticity_token
  respond_to :json, :xml, :yaml

  def show
    has_required_param(:query) do
      @rubygems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
      respond_with(@rubygems, :yamlish => true)
    end
  end

  private

  def has_required_param(key)
    if params[key]
      yield
    else
      render :text => "Request is missing param #{key.inspect}", :status => :bad_request
    end
  end
end
