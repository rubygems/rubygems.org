class RubygemsController < ApplicationController
  include LatestVersion
  before_action :set_reserved_gem, only: %i[show security_events], if: :reserved?
  before_action :find_rubygem, only: %i[show security_events], unless: :reserved?
  before_action :latest_version, only: %i[show], unless: :reserved?
  before_action :find_versioned_links, only: %i[show], unless: :reserved?
  before_action :set_page, only: :index
  before_action :redirect_to_signin, unless: :signed_in?, only: %i[security_events]
  before_action :render_forbidden, unless: :owner?, only: %i[security_events]

  def index
    respond_to do |format|
      format.html do
        @letter = Rubygem.letterize(gem_params[:letter])
        @gems   = Rubygem.letter(@letter).includes(:latest_version, :gem_download).page(@page)
      end
      format.atom do
        @versions = Version.published.limit(Gemcutter::DEFAULT_PAGINATION)
        render "versions/feed"
      end
    end
  end

  def show
    if @reserved_gem
      render "reserved"
    else
      @versions = @rubygem.public_versions.limit(5)
      @adoption = @rubygem.ownership_call
      if @versions.to_a.any?
        render "show"
      else
        render "show_yanked"
      end
    end
  end

  def security_events
    @security_events = @rubygem.events.order(id: :desc).page(params[:page]).per(50)
    render Rubygems::SecurityEventsView.new(rubygem: @rubygem, security_events: @security_events)
  end

  private

  def reserved?
    GemNameReservation.reserved?(params[:id])
  end

  def set_reserved_gem
    @reserved_gem = params[:id].downcase
  end

  def gem_params
    params.permit(:letter, :format, :page)
  end
end
