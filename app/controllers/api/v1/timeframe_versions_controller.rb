class Api::V1::TimeframeVersionsController < Api::BaseController
  skip_before_action :verify_authenticity_token
  before_action :set_page, only: :index

  def index
    if from_time.nil? || to_time.nil?
      render plain: 'timeframe parameters must be iso8601 formatted',
             status: :bad_request
    else
      render_rubygems(version_timeframe_query)
    end
  end

  private

  def from_time
    @parse_from_time ||= Time.iso8601(params.require(:from))
  rescue ArgumentError
    return
  end

  def to_time
    @to_time ||= params[:to].blank? ? Time.zone.now : Time.iso8601(params[:to])
  rescue ArgumentError
    return
  end

  def version_timeframe_query
    Version
      .where(created_at: from_time..to_time)
      .order(:created_at)
      .paginate(page: @page)
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
