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

  EXPLORE_SECTION_SIZE = 5
  MOST_DEPENDED_ON_CACHE_KEY = "rubygems/explore/most_depended_on"

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
    @versions = @rubygem.public_versions_with_extra_version
    @advisories = @rubygem.advisories.visible.to_a
    if @versions.to_a.any?
      @previous_version, @next_version = @latest_version.previous_and_next_in_display_order
      add_breadcrumb @rubygem.name, rubygem_path(@rubygem.slug)
      add_breadcrumb t("breadcrumbs.latest_version", version: @latest_version.display_id)
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

  def explore
    explore_gems = Rubygem.preload(:latest_version, :gem_download)
    recent_window = Gemcutter::NEWS_DAYS_LIMIT.ago..Time.current
    # Match most_recent_version's preference for a Ruby release, falling back
    # to the latest platform release. Rank and display that exact version.
    latest_version_ids = Version.latest.where(rubygem_id: Version.latest.where(created_at: recent_window).select(:rubygem_id))
      .order(:rubygem_id, Arel.sql("CASE WHEN platform = 'ruby' THEN 0 ELSE 1 END"), :position, id: :desc)
      .pluck(Arel.sql("DISTINCT ON (rubygem_id) versions.id"))
    downloaded_versions = Version.joins(:gem_download).order("gem_downloads.count DESC", created_at: :desc)
      .preload(:gem_download, rubygem: :latest_version).limit(EXPLORE_SECTION_SIZE)
    @just_released = downloaded_versions.where(id: latest_version_ids, created_at: recent_window)
    @new_gems = downloaded_versions.where(rubygem_id: Rubygem.with_versions.with_one_version
      .where(created_at: Gemcutter::NEWS_DAYS_LIMIT.ago..).reselect(:id))
    @popular = explore_gems.popular(Gemcutter::POPULAR_DAYS_LIMIT).limit(EXPLORE_SECTION_SIZE)
    @with_provenance = @just_released.with_provenance.reorder(created_at: :desc)
    @most_depended_on_counts = most_depended_on_counts
    most_depended_on = explore_gems.with_versions.where(id: @most_depended_on_counts.keys).index_by(&:id)
    @most_depended_on = @most_depended_on_counts.keys.filter_map { |id| most_depended_on[id] }
    add_breadcrumb t(".breadcrumb")
    set_surrogate_key "explore"
    cache_expiry_headers(expiry: 60, fastly_expiry: 60) if cacheable_request?
  end

  private

  # The aggregate scans every latest release (seconds on production data) and
  # changes slowly, so it is cached; race_condition_ttl lets other requests keep
  # serving the old value while one request recomputes it.
  def most_depended_on_counts
    Rails.cache.fetch(MOST_DEPENDED_ON_CACHE_KEY, expires_in: 1.day, race_condition_ttl: 5.minutes) do
      Rubygem.most_depended_on_counts(EXPLORE_SECTION_SIZE)
    end
  end

  def show_reserved_gem
    return unless GemNameReservation.reserved?(params[:id])
    @reserved_gem = params.expect(:id).downcase
    render "reserved"
  end

  def gem_params
    params.permit(:letter, :format, :page)
  end
end
