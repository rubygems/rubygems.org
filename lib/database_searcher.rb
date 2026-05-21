# frozen_string_literal: true

# Drop-in alternative to ElasticSearcher backed by PostgreSQL full-text search, swapped
# in behind the :postgres_search feature flag. Shares ElasticSearcher's #search /
# #api_search / #suggestions interface and error classes.
class DatabaseSearcher
  # Subset of Rubygem#search_data returned by the API, matching ElasticSearcher#api_source.
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
    results = full_text_search
      .preload(:versions, :linkset, :link_verifications, most_recent_version: :dependencies)
      .page(@page).per(Kaminari.config.default_per_page)
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

    body_q = Rubygem.sanitize_sql_array(["websearch_to_tsquery('english', ?)", @query])

    Rubygem
      .with_versions
      .joins(:gem_download)
      .where("rubygems.search_vector @@ #{body_q}")
      .select("rubygems.*, #{rank_sql(body_q)} AS search_rank")
      .order(Arel.sql("search_rank DESC, rubygems.id DESC"))
      .preload(:latest_version, :gem_download)
  end

  # Popularity-weighted text relevance, plus additive boosts that lift exact- and
  # prefix-name matches above incidental body hits. The boost constants exceed the base
  # term's range, so an exact name always ranks first while downloads order within a tier.
  # `body_q` must be a sanitized SQL fragment — it is interpolated raw.
  def rank_sql(body_q)
    exact  = Rubygem.sanitize_sql_array(["lower(rubygems.name) = lower(?)", @query])
    prefix = Rubygem.sanitize_sql_array(["rubygems.name ILIKE ?", "#{sanitize_like(@query)}%"])

    <<~SQL.squish
      (CASE WHEN #{exact} THEN 1000 ELSE 0 END)
      + (CASE WHEN #{prefix} THEN 30 ELSE 0 END)
      + ts_rank(rubygems.search_vector, #{body_q}) * ln(gem_downloads.count + 2)
    SQL
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
