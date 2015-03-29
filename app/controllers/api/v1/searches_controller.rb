class Api::V1::SearchesController < Api::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_page, only: :show

  def show
    @rubygems = Rubygem.search(params.require(:query)).with_versions.paginate(page: @page)
    respond_to do |format|
      format.json { render json: @rubygems }
      format.yaml { render yaml: @rubygems }
    end
  end
end
