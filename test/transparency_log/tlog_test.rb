# frozen_string_literal: true

require "test_helper"

class TransparencyLog::TlogTest < ActiveSupport::TestCase
  setup do
    @json_payload = { name: "rack", version: "1.0.0" }.to_json
    @tlog = TransparencyLog::Tlog.new
  end

  test "creates entry and posts it to transparency log" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .with(
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

    response = @tlog.create_entry(@json_payload)

    assert_equal "201", response.code
    assert_equal(
      { "uuid" => "abc", "logIndex" => 1 },
      JSON.parse(response.body)
    )
  end
end
