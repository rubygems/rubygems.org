# frozen_string_literal: true

# Name-only search backed by Postgres (pg_trgm), used in place of ElasticSearcher
# for plain-text queries when FeatureFlag::DB_SEARCH is enabled.
#
# Matching: the query must match the start of a name segment (names split on
# Patterns::SPECIAL_CHARACTERS), and whitespace in the query matches those
# separators, so "rails html" finds "rails-html-sanitizer" but "async" does not
# find "carinariasyncytium".
#
# Ranking blends match quality with popularity, mirroring ElasticSearcher's
# log1p(downloads) boost:
#   (similarity + exact-name bonus + prefix bonus) * ln(2 + downloads)
class DatabaseSearcher
  # Queries shorter than this can't use the trigram index, so they only match
  # names that start with the query.
  TRIGRAM_MIN_LENGTH = 3
  SUGGESTIONS_LIMIT = 30

  # Plain-text tokens that look like gem names. Anything else (field:value,
  # quotes, wildcards, boolean operators, leading +/-) is advanced query syntax
  # and stays on OpenSearch.
  PLAIN_TOKEN = /\A[A-Za-z0-9][A-Za-z0-9#{Regexp.escape(Patterns::SPECIAL_CHARACTERS)}]*\z/
  QUERY_OPERATORS = %w[AND OR NOT].freeze

  # Postgres regex fragments for Patterns::SPECIAL_CHARACTERS ("-" first so it's literal).
  SEPARATOR_CLASS = "[-_.]"
  SEGMENT_START = "(^|#{SEPARATOR_CLASS})".freeze

  RANK_SQL = <<~SQL.squish
    (similarity(rubygems.name, :query)
      + (LOWER(rubygems.name) = :query)::int
      + 0.5 * (rubygems.name ILIKE :prefix)::int
    ) * LN(2 + gem_downloads.count) DESC,
    gem_downloads.count DESC,
    rubygems.name ASC
  SQL

  def self.use_for?(query)
    FeatureFlag.enabled?(FeatureFlag::DB_SEARCH) && plain_query?(query)
  end

  def self.plain_query?(query)
    tokens = SearchQuerySanitizer.sanitize(query).split
    tokens.any? && tokens.none? { |token| QUERY_OPERATORS.include?(token) } && tokens.all?(PLAIN_TOKEN)
  end

  def initialize(query, page: 1)
    @query = SearchQuerySanitizer.sanitize(query).downcase
    # Alphanumeric runs only, so terms are always safe to interpolate into the regex.
    @terms = @query.scan(/[a-z0-9]+/)
    @page = page
  end

  def search
    gems = matching.order(Arel.sql(rank_sql)).preload(:latest_version, :gem_download)
      .page(@page).per(Kaminari.config.default_per_page).load
    [nil, gems]
  rescue ActiveRecord::StatementInvalid => e
    Rails.error.report(e, handled: true)
    StatsD.increment("search.failure", tags: { exception: e.class.name, engine: "database" })
    ["Search is currently unavailable. Please try again later.", nil]
  end

  def suggestions
    return [] if @terms.empty?

    Rubygem.with_versions.where("UPPER(rubygems.name) LIKE UPPER(?)", "#{like_escape(@query)}%")
      .by_downloads.limit(SUGGESTIONS_LIMIT).pluck(:name)
  rescue ActiveRecord::StatementInvalid => e
    Rails.error.report(e, handled: true)
    StatsD.increment("search.failure", tags: { exception: e.class.name, engine: "database" })
    []
  end

  private

  def matching
    scope = Rubygem.with_versions.joins(:gem_download)
    return scope.none if @terms.empty?

    if @terms.join.length < TRIGRAM_MIN_LENGTH
      # Single characters only match exactly; two characters match as a prefix.
      # Both use index_rubygems_upcase instead of scanning the table.
      pattern = @terms.join.length == 1 ? like_escape(@query) : "#{like_escape(@query)}%"
      scope.where("UPPER(rubygems.name) LIKE UPPER(?)", pattern)
    else
      # The ILIKE lets the trigram index narrow candidates; the regex enforces
      # that the terms start a name segment and are joined by separators.
      scope.where("rubygems.name ILIKE ?", "%#{@terms.join('%')}%")
        .where("rubygems.name ~* ?", SEGMENT_START + @terms.join(SEPARATOR_CLASS))
    end
  end

  def rank_sql
    Rubygem.sanitize_sql_array([RANK_SQL, query: @query, prefix: "#{like_escape(@query)}%"])
  end

  def like_escape(value)
    Rubygem.sanitize_sql_like(value)
  end
end
