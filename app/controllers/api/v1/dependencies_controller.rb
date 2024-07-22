class Api::V1::DependenciesController < Api::BaseController
  def index
    cache_expiry_headers(expiry: 30, fastly_expiry: 60)
    set_surrogate_key("dependencyapi")

    respond_to do |format|
      error = "The dependency API has gone away. See https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html for more information"
      format.marshal { render plain: error, status: :not_found }
      format.json { render json: { error: error, code: 404 }, status: :not_found }
    end
  end
end
