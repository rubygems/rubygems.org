require "test_helper"

class SendgridWebhookTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "responds 200 OK to valid credentials" do
    params = [
      { sg_event_id: "nwlyJ3Ej3wUBZQiaCAL5YA==", timestamp: Time.current.to_i }
    ]
    post "/sendgrid_events", params: params, as: :json, headers: authorization_header

    assert_response :ok
  end

  test "responds 401 Unauthorized to invalid credentials" do
    params = [
      { sg_event_id: "nwlyJ3Ej3wUBZQiaCAL5YA==", timestamp: Time.current.to_i }
    ]
    post "/sendgrid_events", params: params, as: :json, headers: authorization_header(password: "wrong-password")

    assert_response :unauthorized
  end

  test "errors if credentials configured on server are invalid" do
    SendgridEventsController.any_instance.stubs(:http_basic_authentication_options_valid?).returns(false)
    params = [
      { sg_event_id: "nwlyJ3Ej3wUBZQiaCAL5YA==", timestamp: Time.current.to_i }
    ]

    error = assert_raises(RuntimeError) do
      post "/sendgrid_events", params: params, as: :json, headers: authorization_header
    end

    assert_equal("Invalid authentication options", error.message)
  end

  test "saves events and schedules jobs" do
    params = [
      { email: "user1@example.com", sg_event_id: "nwlyJ3Ej3wUBZQiaCAL5YA==", timestamp: Time.current.to_i, event: "bounce" },
      { email: "user2@example.com", sg_event_id: "t61hI0Xpmk8XSR1YX4s0Kg==", timestamp: Time.current.to_i, event: "delivered" }
    ]
    assert_enqueued_jobs 2, only: ProcessSendgridEventJob do
      post "/sendgrid_events", params: params, as: :json, headers: authorization_header
    end

    assert_response :ok

    events = SendgridEvent.all

    assert_equal 2, events.size
    assert_equal "user1@example.com", events.first.email
    assert_equal "user2@example.com", events.last.email
    assert events.all?(&:pending?)
  end

  def authorization_header(password: "password")
    username = "test_sendgrid_webhook_user"
    encoded_credentials = Base64.encode64("#{username}:#{password}")
    { "Authorization" => "Basic #{encoded_credentials}" }
  end
end
