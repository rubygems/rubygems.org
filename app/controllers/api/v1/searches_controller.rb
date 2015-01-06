class Api::V1::SearchesController < Api::BaseController

  skip_before_filter :verify_authenticity_token
  respond_to :json, :yaml

  def show
    return unless has_required_params?(:query)
    @rubygems = Rubygem.search(params[:query]).with_versions.paginate(:page => params[:page])
    respond_with(@rubygems, :yamlish => true)
  end
end
