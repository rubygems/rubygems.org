# frozen_string_literal: true

require "test_helper"

class TransparencyLog::ClientTest < ActiveSupport::TestCase
  setup do
    @transparency_log_event = create(:transparency_log_event)
    @entry = TransparencyLog::EntryBuilder.new.build(@transparency_log_event)
    @client = TransparencyLog::Client.new("https://example.test")
  end

  test "posts entry to rekor log entries endpoint" do
    stub_request(:post, "https://example.test/api/v2/log/entries")
      .to_return(status: 200, body: {}.to_json)

    @client.post(@entry)

    assert_requested :post, "https://example.test/api/v2/log/entries", times: 1
  end

  test "post calls rekor log entries endpoint with appropriate headers" do
    stub_request(:post, "https://example.test/api/v2/log/entries")
      .to_return(status: 200, body: {}.to_json)

    @client.post(@entry)

    assert_requested(
      :post,
      "https://example.test/api/v2/log/entries",
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      },
      times: 1
    )
  end

  test "returns rekor response as json" do
    stub_request(:post, "https://example.test/api/v2/log/entries")
      .to_return(status: 200, body: {}.to_json)

    response = @client.post(@entry)

    assert_equal({}, response)
  end

  test "raises error for non-success response codes" do
    [400, 401, 403, 404, 409, 422, 500, 502, 503, 504].each do |status_code|
      stub_request(:post, "https://example.test/api/v2/log/entries")
        .to_return(status: status_code, body: "Error")

      error = assert_raises TransparencyLog::Client::Error do
        @client.post(@entry)
      end

      assert_equal "Request failed (#{status_code})", error.message
    end
  end

  test "raises network errors" do
    [Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED].each do |error_class|
      stub_request(:post, "https://example.test/api/v2/log/entries")
        .to_raise(error_class)

      assert_raises(error_class) do
        @client.post(@entry)
      end
    end
  end
end
