class Api::MetricsController < Api::BaseController
  def create
    render json: params
  end
end
