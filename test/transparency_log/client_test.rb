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

    @client.post(@entry)

    assert_requested :post, "https://example.test/api/v2/log/entries", times: 1
  end
end
