class Api::V1::TimeframeVersionsController < Api::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_page, only: :index

  MAXIMUM_TIMEFRAME_QUERY_IN_DAYS = 7
  class InvalidTimeframeParameterError < StandardError ; end

  def index
    render_rubygems(Version.created_between(query_time_range).paginate(page: @page))
  rescue InvalidTimeframeParameterError => ex
    render plain: ex.message, status: :bad_request
  end

  private

  def query_time_range
    parse_time_range_from_params.tap do |range|
      if (range.max - range.min).to_i > MAXIMUM_TIMEFRAME_QUERY_IN_DAYS.days
        raise InvalidTimeframeParameterError,
              "the supplied query time range cannot exceed #{MAXIMUM_TIMEFRAME_QUERY_IN_DAYS} days"
      end
    end
  end

  def parse_time_range_from_params
    from = Time.iso8601(params.require(:from))
    to = params[:to].blank? ? Time.zone.now : Time.iso8601(params[:to])

    from..to
  rescue ArgumentError
    raise InvalidTimeframeParameterError, "timeframe parameters must be iso8601 formatted"
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
