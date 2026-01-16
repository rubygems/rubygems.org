class SearchQuerySanitizer
  MAX_QUERY_LENGTH = 500
  MAX_FIELD_OCCURRENCES = 2
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
    raise MalformedQueryError, "Range syntax not supported" if @query.match?(/[\[{][^\]}]*TO[^\]}]*[\]}]/i)
  end

  def collapse_redundant_fields!
    ALLOWED_FIELDS.each do |field|
      pattern = /\b#{field}:\S+/i
      occurrences = @query.scan(pattern)
      next unless occurrences.length > MAX_FIELD_OCCURRENCES

      count = 0
      @query = @query.gsub(pattern) do |match|
        count += 1
        count <= MAX_FIELD_OCCURRENCES ? match : ""
      end.squeeze(" ").strip
    end
  end

  def escape_dangerous_patterns!
    @query = @query.gsub(/(\*{2,}|\?{2,})/) { |m| m[0] } # Collapse repeated wildcards
    @query = @query.delete("\u0000") # Remove null bytes
  end
end
