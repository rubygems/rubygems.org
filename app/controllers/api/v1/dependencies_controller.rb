class Api::V1::DependenciesController < Api::BaseController
  before_action :check_gem_count
  GEM_REQUEST_LIMIT = 200

  def index
    deps = GemDependent.new(gem_names).to_a

    response.headers['Surrogate-Control'] = 'max-age=60'
    respond_to do |format|
      format.json { render json: deps }
      format.marshal { render text: Marshal.dump(deps) }
    end
  end

  private

  def check_gem_count
    return render text: '' if gem_names.empty?
    return if gem_names.size <= GEM_REQUEST_LIMIT

    if request.format == :marshal
      render text: "Too many gems! (use --full-index instead)", status: 422
    elsif request.format == :json
      render json: { error: 'Too many gems! (use --full-index instead)', code: 422 }, status: 422
    end
  end

  def gem_names
    @gem_names ||= params[:gems].blank? ? [] : params[:gems].split(",".freeze)
  end
end
