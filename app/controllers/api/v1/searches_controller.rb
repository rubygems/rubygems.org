class Api::V1::SearchesController < Api::BaseController
  before_action :set_page, only: %i[show autocomplete]
  before_action :verify_query_string, only: %i[show autocomplete]

  def show
    @rubygems = ElasticSearcher.new(query_params, page: @page).search(api: true)
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end

  def autocomplete
    results = ElasticSearcher.new(params[:query], page: @page).suggestions
    render json: results
  end

  private

  def verify_query_string
    render plain: "bad request", status: :bad_request unless query_params.is_a?(String)
  end

  def query_params
    params.require(:query)
  end
end
