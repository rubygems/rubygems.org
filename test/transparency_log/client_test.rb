# frozen_string_literal: true

require "test_helper"

class TransparencyLog::ClientTest < ActiveSupport::TestCase
  setup do
    @url = "http://example.test"
    @client = TransparencyLog::Client.new(@url)
  end

  test "posts entry to rekor log entries endpoint" do
    entry = {
      "hashedRekordRequestV002" => {
        "digest" => "abc123",
        "signature" => {
          "content" => "signature123",
          "verifier" => {
            "publicKey" => {
              "rawBytes" => "publickey123"
            },
            "keyDetails" => "PKIX_ECDSA_P256_SHA_256"
          }
        }
      }
    }

    stub_request(:post, "#{@url}/api/v2/log/entries")
      .with(
        body: JSON.dump(entry),
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      )
      .to_return(
        status: 201,
        body: { uuid: "abc", logIndex: 1 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = @client.post(entry)

    assert_equal "201", response.code
    assert_equal(
      { "uuid" => "abc", "logIndex" => 1 },
      JSON.parse(response.body)
    )
  end
end
