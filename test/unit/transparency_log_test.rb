# frozen_string_literal: true

require "test_helper"

class TransparencyLogTest < ActiveSupport::TestCase
  test "#configure" do
    TransparencyLog.configure do |c|
      c.rekor_url = "https://example.com"
    end

    assert_equal TransparencyLog::Client.new.rekor_url, "https://example.com"
  end
end
