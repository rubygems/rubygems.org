# frozen_string_literal: true

require "test_helper"

class Gemcutter::DatadogSearchErrorProcessorTest < ActiveSupport::TestCase
  Trace = Data.define(:spans)

  setup do
    @processor = Gemcutter::DatadogSearchErrorProcessor.new
  end

  test "retains expected query parser rejection spans without error classification" do
    opensearch = search_span(parser_rejection_error)
    faraday = transport_span("faraday.request", parent_id: opensearch.id)
    http = transport_span("http.request", parent_id: faraday.id)
    trace = Trace.new([http, faraday, opensearch])
    original_ids = trace.spans.map(&:id)

    result = @processor.call(trace)

    assert_same trace, result
    assert_equal original_ids, trace.spans.map(&:id)
    trace.spans.each do |span|
      assert_equal 0, span.status
      assert_equal "400", span.get_tag("http.status_code")
      assert_equal "true", span.get_tag("search.invalid_query")
      Gemcutter::DatadogSearchErrorProcessor::ERROR_TAGS.each { |tag| refute span.has_tag?(tag) }
    end
  end

  test "leaves other OpenSearch bad requests and their transport spans classified as errors" do
    opensearch = search_span({ error: { type: "illegal_argument_exception", reason: "Unknown analyzer" } }.to_json)
    faraday = transport_span("faraday.request", parent_id: opensearch.id)
    http = transport_span("http.request", parent_id: faraday.id)

    @processor.call(Trace.new([http, faraday, opensearch]))

    [http, faraday, opensearch].each do |span|
      assert_equal 1, span.status
      assert span.has_tag?("error.type")
    end
  end

  test "leaves malformed, non-search, and non-400 spans unchanged" do
    malformed = search_span("not JSON")
    autocomplete = search_span(parser_rejection_error, resource: "POST https://search.example/rubygems/_search/suggest")
    server_error = search_span(parser_rejection_error, status: 500)

    [malformed, autocomplete, server_error].each do |span|
      @processor.call(Trace.new([span]))

      assert_equal 1, span.status
      assert span.has_tag?("error.type")
    end
  end

  private

  def search_span(error_message, resource: "POST https://search.example/rubygems/_search", status: 400)
    Datadog::Tracing::Span.new(
      "opensearch.query",
      resource:,
      status: 1,
      meta: {
        "http.status_code" => status.to_s,
        "error.type" => "OpenSearch::Transport::Transport::Errors::BadRequest",
        "error.message" => error_message,
        "error.stack" => "stack"
      }
    )
  end

  def transport_span(name, parent_id:)
    Datadog::Tracing::Span.new(
      name,
      parent_id:,
      status: 1,
      meta: {
        "http.status_code" => "400",
        "error.type" => "Error 400",
        "error.message" => "Bad Request",
        "error.stack" => "stack"
      }
    )
  end

  def parser_rejection_error
    {
      error: {
        failed_shards: [
          reason: {
            type: "query_shard_exception",
            reason: "Failed to parse query [rails AND]",
            caused_by: { type: "parse_exception", reason: "Unexpected EOF" }
          }
        ]
      },
      status: 400
    }.to_json
  end
end
