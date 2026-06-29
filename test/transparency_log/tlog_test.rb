# frozen_string_literal: true

require "test_helper"

class TransparencyLog::TlogTest < ActiveSupport::TestCase
  setup do
    @transparency_log_event = create(:transparency_log_event)
    @tlog = TransparencyLog::Tlog.new
  end

  test "creates entry and posts it to transparency log" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .to_return(status: 200, body: {}.to_json)

    @tlog.create_entry(@transparency_log_event)

    assert_requested :post, "http://localhost:3004/api/v2/log/entries", times: 1
  end

  test "logs error and raises for client errors" do
    stub_request(:post, "http://localhost:3004/api/v2/log/entries")
      .to_return(status: 400, body: "Bad Request")

    assert_raises TransparencyLog::Client::Error do
      @tlog.create_entry(@transparency_log_event)
    end
  end
end
