# frozen_string_literal: true

class RubygemsController < ApplicationController
  include LatestVersion

  before_action :show_reserved_gem, only: %i[show security_events]
  before_action :find_rubygem, only: %i[show security_events]
  before_action :latest_version, only: %i[show security_events]
  before_action :find_versioned_links, only: %i[show security_events]
  before_action :set_page, only: :index
  before_action :redirect_to_signin, unless: :signed_in?, only: %i[security_events]

  layout "subject", only: %i[show security_events]

  def index
    respond_to do |format|
      format.html do
        @letter = Rubygem.letterize(gem_params[:letter])
        @gems   = Rubygem.letter(@letter).includes(:latest_version, :gem_download).page(@page)
        add_breadcrumb t(".title")
      end
      format.atom do
        @versions = Version.published.limit(Gemcutter::DEFAULT_PAGINATION)
        render "versions/feed"
      end
    end
    set_surrogate_key "gems/index"
    cache_expiry_headers(expiry: 60, fastly_expiry: 60) if cacheable_request?
  end

  def show
    @versions = @rubygem.public_versions.limit(5)
    if @versions.to_a.any?
      add_breadcrumb @rubygem.name, rubygem_path(@rubygem.slug)
      add_breadcrumb t("breadcrumbs.latest_version", version: @latest_version.slug)
      render "show"
    else
      add_breadcrumb @rubygem.name
      render "show_yanked"
    end
    set_surrogate_key "gem/#{@rubygem.name}"
    cache_expiry_headers(expiry: 60, fastly_expiry: 60) if cacheable_request?
  end

  def security_events
    authorize @rubygem, :show_events?
    @security_events = @rubygem.events.order(id: :desc).page(params[:page]).per(50)
    add_breadcrumb @rubygem.name, rubygem_path(@rubygem.slug)
    add_breadcrumb t(".title")
  end

  private

  def show_reserved_gem
    return unless GemNameReservation.reserved?(params[:id])
    @reserved_gem = params.expect(:id).downcase
    render "reserved"
  end

  def gem_params
    params.permit(:letter, :format, :page)
  end
end
