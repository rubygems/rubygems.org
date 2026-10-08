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
        browsing_by_letter? ? index_letter : index_explore
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
    @advisories = @rubygem.advisories.visible(current_user).to_a
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

  private

  # Letter and page links predate the Explore hub, so either one keeps
  # rendering the A–Z listing.
  def browsing_by_letter?
    gem_params[:letter].present? || gem_params[:page].present?
  end

  def index_letter
    @letter = Rubygem.letterize(gem_params[:letter])
    @gems   = Rubygem.letter(@letter).includes(:latest_version, :gem_download).page(@page)
    add_breadcrumb t(".title"), rubygems_path
    add_breadcrumb @letter
  end

  def index_explore
    explore_gems = Rubygem.preload(:latest_version, :gem_download)
    @just_released = explore_gems.news(Gemcutter::NEWS_DAYS_LIMIT).limit(EXPLORE_SECTION_SIZE)
    @new_gems = explore_gems.with_versions.where(created_at: Gemcutter::NEWS_DAYS_LIMIT.ago..).latest(EXPLORE_SECTION_SIZE)
    @popular = explore_gems.popular(Gemcutter::POPULAR_DAYS_LIMIT).limit(EXPLORE_SECTION_SIZE)
    @with_provenance = explore_gems.news_with_provenance(Gemcutter::NEWS_DAYS_LIMIT).limit(EXPLORE_SECTION_SIZE)
    @most_depended_on_counts = most_depended_on_counts
    most_depended_on = explore_gems.with_versions.where(id: @most_depended_on_counts.keys).index_by(&:id)
    @most_depended_on = @most_depended_on_counts.keys.filter_map { |id| most_depended_on[id] }
    add_breadcrumb t(".title")
    render "explore"
  end

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
