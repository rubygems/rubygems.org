require "test_helper"

class SearchQuerySanitizerTest < ActiveSupport::TestCase
  test "query that exceeds the max length raises QueryTooLongError" do
    long_query = "a" * (SearchQuerySanitizer::MAX_QUERY_LENGTH + 1)
    assert_raises(SearchQuerySanitizer::QueryTooLongError) { SearchQuerySanitizer.sanitize(long_query) }
  end

  test "reject bracket range syntax" do
    assert_raises(SearchQuerySanitizer::MalformedQueryError) { SearchQuerySanitizer.sanitize("updated:[2024-01-01 TO 2024-12-31]") }
    assert_raises(SearchQuerySanitizer::MalformedQueryError) { SearchQuerySanitizer.sanitize("downloads:{100 TO 1000}") }
    assert_raises(SearchQuerySanitizer::MalformedQueryError) { SearchQuerySanitizer.sanitize("updated:[2024-01-01 TO *}") }
  end

  test "allow comparison operators" do
    assert_equal "downloads:>20000", SearchQuerySanitizer.sanitize("downloads:>20000")
    assert_equal "updated:>2024-01-01", SearchQuerySanitizer.sanitize("updated:>2024-01-01")
  end

  test "allow two occurrences of same field" do
    assert_equal "updated:>2024-01-01 updated:<2024-12-31", SearchQuerySanitizer.sanitize("updated:>2024-01-01 updated:<2024-12-31")
  end

  test "collapse more than two occurrences of same field" do
    result = SearchQuerySanitizer.sanitize("updated:>a AND updated:>b AND updated:>c AND updated:>d")

    assert_equal 2, result.scan(/updated:/i).length
  end

  test "collapse redundant fields across all allowed fields" do
    result = SearchQuerySanitizer.sanitize("name:a name:b name:c downloads:>1 downloads:>2 downloads:>3")

    assert_equal 2, result.scan(/name:/i).length
    assert_equal 2, result.scan(/downloads:/i).length
  end

  test "collapse repeated wildcards" do
    assert_equal "name:*", SearchQuerySanitizer.sanitize("name:****")
  end

  test "collapse repeated question marks" do
    assert_equal "name:?", SearchQuerySanitizer.sanitize("name:????")
  end

  test "remove null bytes" do
    assert_equal "railstest", SearchQuerySanitizer.sanitize("rails\u0000test")
  end

  test "preserve AND operator" do
    assert_equal "rails AND api", SearchQuerySanitizer.sanitize("rails AND api")
  end

  test "preserve OR operator" do
    assert_equal "active OR action", SearchQuerySanitizer.sanitize("active OR action")
  end

  test "preserve field searches" do
    assert_equal "name:rails summary:ORM", SearchQuerySanitizer.sanitize("name:rails summary:ORM")
  end

  test "preserve single wildcard" do
    assert_equal "name:web*", SearchQuerySanitizer.sanitize("name:web*")
  end

  test "preserve complex legitimate queries" do
    query = "rails AND api OR name:web* downloads:>1000"

    assert_equal query, SearchQuerySanitizer.sanitize(query)
  end

  test "return empty string for nil query" do
    assert_equal "", SearchQuerySanitizer.sanitize(nil)
  end

  test "return empty string for empty query" do
    assert_equal "", SearchQuerySanitizer.sanitize("")
  end

  test "return empty string for whitespace-only query" do
    assert_equal "", SearchQuerySanitizer.sanitize("   ")
  end

  test "strip leading and trailing whitespace" do
    assert_equal "rails", SearchQuerySanitizer.sanitize("  rails  ")
  end

  test "logs rejected queries with details" do
    Rails.logger.expects(:warn).with(includes("[SearchQuerySanitizer] Rejected query"))

    assert_raises(SearchQuerySanitizer::QueryTooLongError) do
      SearchQuerySanitizer.sanitize("a" * (SearchQuerySanitizer::MAX_QUERY_LENGTH + 1))
    end
  end
end
