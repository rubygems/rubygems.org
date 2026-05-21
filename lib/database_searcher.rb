# frozen_string_literal: true

# PostgreSQL full-text search over the `rubygems.search_vector` tsvector column
# (see RubygemSearchable#update_search_vector and AddSearchVectorToRubygems).
#
# Drop-in alternative to ElasticSearcher: exposes the same #search, #api_search and
# #suggestions interface so the controllers can switch between the two behind the
# :postgres_search feature flag without any other changes. Reuses ElasticSearcher's
# error classes so existing rescue_from handlers keep working.
class DatabaseSearcher
  # Fields returned by the API, mirroring ElasticSearcher#api_source. These are keys
  # of Rubygem#search_data so the JSON/YAML response matches the OpenSearch one.
  API_FIELDS = %i[
    name downloads version version_downloads platform authors info licenses metadata
    sha project_uri gem_uri homepage_uri wiki_uri documentation_uri mailing_list_uri
    funding_uri source_code_uri bug_tracker_uri changelog_uri
  ].freeze

  SUGGESTIONS_LIMIT = 30

  def initialize(query, page: 1)
    @query = SearchQuerySanitizer.sanitize(query)
    @page = page
  end

  def search
    [nil, full_text_search.page(@page).per(Kaminari.config.default_per_page)]
  rescue StandardError => e
    [error_msg(e), nil]
  end

  def api_search
    results = full_text_search.page(@page).per(Kaminari.config.default_per_page)
    results.map { |rubygem| rubygem.search_data.slice(*API_FIELDS) }
  rescue StandardError => e
    raise ElasticSearcher::SearchNotAvailableError, error_msg(e)
  end

  def suggestions
    return [] if @query.blank?

    Rubygem
      .with_versions
      .where("name ILIKE ?", "#{sanitize_like(@query)}%")
      .by_downloads
      .limit(SUGGESTIONS_LIMIT)
      .pluck(:name)
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    StatsD.increment("search.failure", tags: { exception: e.class.name })
    []
  end

  private

  def full_text_search
    return Rubygem.none if @query.blank?

    tsquery = Rubygem.sanitize_sql_array(["websearch_to_tsquery('english', ?)", @query])

    Rubygem
      .with_versions
      .joins(:gem_download)
      .where("rubygems.search_vector @@ #{tsquery}")
      .select("rubygems.*, ts_rank(rubygems.search_vector, #{tsquery}) AS search_rank")
      .order(Arel.sql("ts_rank(rubygems.search_vector, #{tsquery}) * ln(gem_downloads.count + 2) DESC"))
      .preload(:latest_version, :gem_download)
  end

  def sanitize_like(value)
    ActiveRecord::Base.sanitize_sql_like(value.strip)
  end

  def error_msg(error)
    Rails.error.report(error, handled: true)
    StatsD.increment("search.failure", tags: { exception: error.class.name })
    "Search is currently unavailable. Please try again later."
  end
end
