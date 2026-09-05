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

  test "anonymous request logs no identity" do
    payload = capture_request_payload { get "/" }

    refute payload.key?(:identity)
  end

  test "signed-in web request logs the user id only" do
    user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    payload = capture_request_payload { get dashboard_path }

    assert_equal({ user_id: user.id }, payload[:identity])
  end

  test "API request logs the user id and api key id" do
    api_key = create(:api_key, key: "12345", scopes: %w[index_rubygems])

    payload = capture_request_payload do
      get api_v1_rubygems_path(format: :json), headers: { "HTTP_AUTHORIZATION" => "12345" }
    end

    assert_response :success
    assert_equal({ user_id: api_key.user.id, api_key_id: api_key.id }, payload[:identity])
  end

  test "API request with a trusted-publisher key logs the api key id without a user id" do
    api_key = create(:api_key, :trusted_publisher, key: "tp-key-12345")

    payload = capture_request_payload do
      # The response itself may be a 403 (trusted-publisher keys have narrow
      # scopes); the payload is built after authentication either way.
      get api_v1_rubygems_path(format: :json), headers: { "HTTP_AUTHORIZATION" => "tp-key-12345" }
    end

    assert_nil payload[:identity][:user_id]
    assert_equal api_key.id, payload[:identity][:api_key_id]
  end
end
