class Api::V1::SearchesController < Api::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_page, only: :show

  def show
    @rubygems = ElasticSearcher.new(query_params, api: true, page: @page).search
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end

  private

  def query_params
    params.require(:query)
  end
end
