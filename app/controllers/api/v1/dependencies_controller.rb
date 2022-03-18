class Api::V1::DependenciesController < Api::BaseController
  before_action :check_gem_count

  def index
    deps = GemDependent.new(gem_names).to_a

    expires_in 30, public: true
    fastly_expires_in 60
    set_surrogate_key("dependencyapi", gem_names.map { |name| "gem/#{name}" })

    respond_to do |format|
      format.json { render json: deps }
      format.marshal { render plain: Marshal.dump(deps) }
    end
  end

  private

  def check_gem_count
    return render plain: "" if gem_names.empty?
    return if gem_names.size <= Gemcutter::GEM_REQUEST_LIMIT

    case request.format.symbol
    when :marshal
      render plain: "Too many gems! (use --full-index instead)", status: :unprocessable_entity
    when :json
      render json: { error: "Too many gems! (use --full-index instead)", code: 422 }, status: :unprocessable_entity
    end
  end

  def gem_names
    @gem_names ||= gems_params[:gems].blank? ? [] : gems_params[:gems].split(",".freeze)
  end

  def gems_params
    params.permit(:gems)
  end
end
