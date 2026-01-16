# Sanitizes user search queries to protect against DoS attacks targeting OpenSearch.
#
# This class validates and transforms search queries to prevent abuse patterns that
# could overwhelm the search cluster. It enforces the following rules:
# - Maximum query length to prevent large payload attacks
# - Blocks bracket range syntax ([x TO y]) which can be expensive to parse
# - Limits repeated field filters to prevent query complexity attacks
# - Escapes dangerous wildcard patterns
#
class SearchQuerySanitizer
  # Maximum allowed query length. 500 characters accommodates legitimate searches
  # while preventing abuse from very long machine-generated queries.
  MAX_QUERY_LENGTH = 500

  # Maximum occurrences of any single field filter (e.g., updated:).
  # Allows date ranges like "updated:>2024-01-01 updated:<2024-12-31"
  # while blocking repeated filters used in DoS attacks.
  MAX_FIELD_OCCURRENCES = 2

  # Maximum total field filters across all field types combined.
  # Prevents attackers from using many different fields to create complex queries.
  MAX_TOTAL_FIELD_FILTERS = 6

  ALLOWED_FIELDS = %w[name summary description downloads updated].freeze

  class QueryTooLongError < StandardError; end
  class MalformedQueryError < StandardError; end

  def self.sanitize(query)
    new(query).sanitize
  end

  def initialize(query)
    @query = query&.to_s&.strip || ""
  end

  def sanitize
    return "" if @query.blank?

    validate_length!
    validate_no_range_syntax!
    collapse_redundant_fields!
    escape_dangerous_patterns!

    @query
  rescue QueryTooLongError, MalformedQueryError => e
    Rails.logger.warn(
      "[SearchQuerySanitizer] Rejected query: " \
      "reason=#{e.class.name} " \
      "query_length=#{@query.length} " \
      "query_preview=#{@query.truncate(100).inspect}"
    )
    raise
  end

  private

  def validate_length!
    raise QueryTooLongError, "Query exceeds max length of #{MAX_QUERY_LENGTH}" if @query.length > MAX_QUERY_LENGTH
  end

  def validate_no_range_syntax!
    # Block bracket range syntax entirely - users should use comparison operators instead
    # e.g., use "updated:>2024-01-01" not "updated:[2024-01-01 TO *]"
    # Uses word boundary \b around TO to avoid false positives like [GOTO] or [AUTOMATOR]
    raise MalformedQueryError, "Range syntax not supported" if @query.match?(/[\[{][^\]}]*\bTO\b[^\]}]*[\]}]/i)
  end

  def collapse_redundant_fields!
    total_field_count = 0

    ALLOWED_FIELDS.each do |field|
      # Pattern matches both unquoted (name:rails) and quoted (name:"web framework") field values
      pattern = /\b#{field}:(?:"[^"]*"|\S+)/i
      occurrences = @query.scan(pattern)
      total_field_count += [occurrences.length, MAX_FIELD_OCCURRENCES].min

      next unless occurrences.length > MAX_FIELD_OCCURRENCES

      count = 0
      @query = @query.gsub(pattern) do |match|
        count += 1
        count <= MAX_FIELD_OCCURRENCES ? match : ""
      end
    end

    # Collapse excess fields if total exceeds limit
    collapse_to_total_limit! if total_field_count > MAX_TOTAL_FIELD_FILTERS

    @query = @query.squeeze(" ").strip
  end

  def collapse_to_total_limit!
    # Build a combined pattern matching any field filter
    combined_pattern = /\b(?:#{ALLOWED_FIELDS.join('|')}):(?:"[^"]*"|\S+)/i
    kept_count = 0

    @query = @query.gsub(combined_pattern) do |match|
      kept_count += 1
      kept_count <= MAX_TOTAL_FIELD_FILTERS ? match : ""
    end
  end

  def escape_dangerous_patterns!
    @query = @query.gsub(/\*{2,}/, "*").gsub(/\?{2,}/, "?") # Collapse repeated wildcards
    @query = @query.delete("\u0000") # Remove null bytes
  end
end
