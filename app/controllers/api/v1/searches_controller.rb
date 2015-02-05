class Api::V1::SearchesController < Api::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_page, only: :show
  respond_to :json, :yaml

  def show
    @rubygems = Rubygem.search(params.require(:query)).with_versions.paginate(page: @page)
    respond_with(@rubygems, yamlish: true)
  end
end
