class Api::V1::SearchesController < Api::BaseController
  before_action :set_page, only: %i[show autocomplete]
  before_action :verify_query_string, only: %i[show autocomplete]

  rescue_from ElasticSearcher::SearchNotAvailableError, with: :search_not_available_error
  rescue_from ElasticSearcher::InvalidQueryError, with: :render_bad_request

  def show
    @rubygems = ElasticSearcher.new(query_params, page: @page).api_search
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end

  def autocomplete
    results = ElasticSearcher.new(query_params, page: @page).suggestions
    render json: results
  end

  private

  def verify_query_string
    render_bad_request unless query_params.is_a?(String)
  end

  def search_not_available_error(error)
    render plain: error.message, status: :service_unavailable
  end

  def query_params
    params_fetch(:query)
  end
end
