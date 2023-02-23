class Api::V1::DependenciesController < Api::BaseController
  before_action :check_brownout
  before_action :check_gem_count

  mattr_reader :brownout_ranges, default: [
    # March 22 at 00:00 UTC (4pm PT / 7pm ET) for 5 minutes
    [Time.utc(2023, 3, 22), 5.minutes],
    # March 29 at the top of every hour UTC for 10 minutes
    *(0..23).map do |h|
      [Time.utc(2023, 3, 29, h), 10.minutes]
    end,
    # April 03 for the entire day UTC
    [Time.utc(2023, 4, 3), 1.day]
  ].map { |start, duration| start..(start + duration) } <<
    # April 10 from 00:00 UTC onward
    (Time.utc(2023, 4, 10)...)

  def index
    deps = GemDependent.new(gem_names).to_a

    cache_expiry_headers(expiry: 30, fastly_expiry: 60)
    set_surrogate_key("dependencyapi", gem_names.map { |name| "gem/#{name}" })

    respond_to do |format|
      format.json { render json: deps }
      format.marshal { render plain: Marshal.dump(deps) }
    end
  end

  private

  def check_brownout
    current_time = Time.current.utc
    return if brownout_ranges.none? { |r| r.cover?(current_time) }

    respond_to do |format|
      error = "The dependency API is going away. See https://blog.rubygems.org/2023/02/22/dependency-api-deprecation.html for more information"
      format.marshal { render plain: error, status: :not_found }
      format.json { render json: { error: error, code: 404 }, status: :not_found }
    end
  end

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
