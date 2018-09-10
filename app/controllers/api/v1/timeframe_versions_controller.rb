class Api::V1::TimeframeVersionsController < Api::BaseController
  class InvalidTimeframeParameterError < StandardError; end
  rescue_from InvalidTimeframeParameterError, with: :bad_request_response
  skip_before_action :verify_authenticity_token
  before_action :set_page, :ensure_valid_timerange, only: :index

  MAXIMUM_TIMEFRAME_QUERY_IN_DAYS = 7

  def index
    render_rubygems(
      Version.created_between(from_time, to_time).paginate(page: @page)
    )
  end

  private

  def bad_request_response(exception)
    render plain: exception.message, status: :bad_request
  end

  def ensure_valid_timerange
    if (to_time - from_time).to_i > MAXIMUM_TIMEFRAME_QUERY_IN_DAYS.days
      raise InvalidTimeframeParameterError,
        "the supplied query time range cannot exceed #{MAXIMUM_TIMEFRAME_QUERY_IN_DAYS} days"
    elsif from_time > to_time
      raise InvalidTimeframeParameterError,
        "the starting time parameter must be before the ending time parameter"
    end
  end

  def from_time
    @from_time ||= Time.iso8601(params.require(:from))
  rescue ArgumentError
    raise InvalidTimeframeParameterError, 'the from parameter must be iso8601 formatted'
  end

  def to_time
    @to_time ||= params[:to].blank? ? Time.zone.now : Time.iso8601(params[:to])
  rescue ArgumentError
    raise InvalidTimeframeParameterError, 'the "to" parameter must be iso8601 formatted'
  end

  def render_rubygems(versions)
    rubygems = versions.includes(:dependencies, rubygem: :linkset).map do |version|
      version.rubygem.payload(version)
    end

    respond_to do |format|
      format.json { render json: rubygems }
      format.yaml { render yaml: rubygems }
    end
  end
end
