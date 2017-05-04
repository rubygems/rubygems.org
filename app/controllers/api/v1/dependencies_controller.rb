class Api::V1::DependenciesController < Api::BaseController
  before_action :check_gem_count
  GEM_REQUEST_LIMIT = 200

  def index
    deps = dependent_reader.new(gem_names).to_a

    expires_in 30, public: true
    fastly_expires_in 60
    set_surrogate_key surrogate_key, gem_names.map { |name| "gem/#{name}" }

    respond_to do |format|
      format.json { render json: deps }
      format.marshal { render plain: Marshal.dump(deps) }
    end
  end

  private

  def surrogate_key
    'dependencyapi'
  end

  def dependent_reader
    GemDependent
  end

  def check_gem_count
    return render plain: '' if gem_names.empty?
    return if gem_names.size <= GEM_REQUEST_LIMIT

    if request.format == :marshal
      render plain: "Too many gems! (use --full-index instead)", status: 422
    elsif request.format == :json
      render json: { error: 'Too many gems! (use --full-index instead)', code: 422 }, status: 422
    end
  end

  def gem_names
    @gem_names ||= params[:gems].blank? ? [] : params[:gems].split(",".freeze)
  end
end
