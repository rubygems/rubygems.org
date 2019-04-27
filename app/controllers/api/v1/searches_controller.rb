class Api::V1::SearchesController < Api::BaseController
  before_action :set_page, only: :show
  before_action :verify_query_string, only: :show

  def show
    @rubygems = ElasticSearcher.new(query_params, api: true, page: @page).search
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end

  private

  def verify_query_string
    render plain: "bad request", status: :bad_request unless query_params.is_a?(String)
  end

  def query_params
    params.require(:query)
  end
end
