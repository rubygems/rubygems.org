# frozen_string_literal: true

require "test_helper"

class TransparencyLog::ClientTest < ActiveSupport::TestCase
  setup do
    @url = "http://example.test"
    @client = TransparencyLog::Client.new(@url)
  end

  test "posts entry to rekor log entries endpoint" do
    entry = {
      apiVersion: "0.0.2",
      kind: "hashedrekord",
      spec: {
        hashedRekordV002: {
          data: {
            algorithm: "SHA2_256",
            digest: "abc123",
          },
          signature: {
            content: "signature123",
          },
        },
      },
    }

    stub_request(:post, "#{@url}/api/v1/log/entries")
      .with(
        body: JSON.generate(entry),
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .to_return(
        status: 201,
        body: { uuid: "abc", logIndex: 1 }.to_json,
        headers: { "Content-Type" => "application/json" },
      )

    response = @client.post(entry)

    assert_equal "201", response.code
    assert_equal(
      { "uuid" => "abc", "logIndex" => 1 },
      JSON.parse(response.body)
    )
  end
end