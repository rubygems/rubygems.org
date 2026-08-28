# frozen_string_literal: true

require "test_helper"

class RequestLogPayloadTest < ActionDispatch::IntegrationTest
  def capture_request_payload
    payloads = []
    subscriber = ActiveSupport::Notifications.subscribe("process_action.action_controller") do |event|
      payloads << event.payload
    end
    yield
    payloads.sole
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "semantic logger is configured with the application name" do
    assert_equal "rubygems.org", SemanticLogger.application
  end

  test "payload carries timestamp, env and client network info" do
    payload = capture_request_payload { get "/" }

    assert_kind_of Time, payload[:timestamp]
    assert_predicate payload[:timestamp], :utc?
    assert_equal "test", payload[:env]
    assert_equal({ client: { ip: "127.0.0.1" } }, payload[:network])
  end

  test "rails block carries controller, action, params, format and timings" do
    payload = capture_request_payload { get "/search?query=rails&utf8=%E2%9C%93" }

    rails = payload[:rails]

    assert_equal "SearchesController", rails[:controller]
    assert_equal "show", rails[:action]
    # utf8 (and routing keys) are stripped; real query params remain
    assert_equal({ "query" => "rails" }, rails[:params])
    assert_equal "html", rails[:format].to_s
    assert_kind_of Numeric, rails[:view_time_ms]
    assert_kind_of Numeric, rails[:db_time_ms]
  end

  test "http block carries request id, method, status and url" do
    payload = capture_request_payload { get "/" }

    http = payload[:http]

    assert_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/, http[:request_id])
    assert_equal "GET", http[:method]
    assert_equal 200, http[:status_code]
    assert_match %r{\Ahttp://[^/]+/\z}, http[:url]
  end

  test "message summarizes status, method, path and controller action" do
    payload = capture_request_payload { get "/" }

    assert_equal "[200] GET / (HomeController#index)", payload[:message]
  end

  test "message reflects non-success statuses" do
    payload = capture_request_payload { get "/gems/definitely-not-a-real-gem" }

    assert_equal "[404] GET /gems/definitely-not-a-real-gem (RubygemsController#show)", payload[:message]
  end
end
