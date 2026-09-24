# frozen_string_literal: true

require "json"

class Gemcutter::DatadogSearchErrorProcessor
  ERROR_TAGS = %w[error.type error.message error.stack].freeze
  TRANSPORT_SPAN_NAMES = %w[faraday.request http.request].freeze

  def call(trace)
    spans = trace.spans
    expected_span_ids = spans.filter_map { |span| span.id if expected_query_parser_rejection?(span) }
    spans_by_id = spans.index_by(&:id)

    spans.each do |span|
      next unless expected_span_ids.include?(span.id) || expected_transport_descendant?(span, spans_by_id, expected_span_ids)

      clear_error_classification(span)
    end

    trace
  end

  private

  def clear_error_classification(span)
    span.status = 0
    ERROR_TAGS.each { |tag| span.clear_tag(tag) }
    span.set_tag("search.invalid_query", true)
  end

  def expected_transport_descendant?(span, spans_by_id, expected_span_ids)
    return false unless TRANSPORT_SPAN_NAMES.include?(span.name)
    return false unless span.get_tag("http.status_code").to_i == 400

    parent = spans_by_id[span.parent_id]
    while parent
      return true if expected_span_ids.include?(parent.id)

      parent = spans_by_id[parent.parent_id]
    end
    false
  end

  def expected_query_parser_rejection?(span)
    return false unless search_bad_request?(span)

    error = JSON.parse(span.get_tag("error.message").delete_prefix("[400] ")).fetch("error")
    reasons = error.fetch("failed_shards", []).filter_map { |shard| shard["reason"] }

    reasons.any? do |reason|
      reason["type"] == "query_shard_exception" &&
        reason["reason"]&.start_with?("Failed to parse query [") &&
        caused_by_parse_exception?(reason["caused_by"])
    end
  rescue JSON::ParserError, KeyError, NoMethodError
    false
  end

  def search_bad_request?(span)
    span.name == "opensearch.query" &&
      span.resource.end_with?("/_search") &&
      span.get_tag("http.status_code").to_i == 400
  end

  def caused_by_parse_exception?(cause)
    return false unless cause.is_a?(Hash)
    return true if cause["type"] == "parse_exception"

    caused_by_parse_exception?(cause["caused_by"])
  end
end
