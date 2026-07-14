# frozen_string_literal: true

require "test_helper"

class TransparencyLogTest < ActiveSupport::TestCase
  test "#configure" do
    TransparencyLog.configure do |config|
      config.rekor_url = "https://example.com"
      config.private_key = "my_private_key"
    end

    assert_equal "https://example.com", TransparencyLog.configuration.rekor_url
    assert_equal "my_private_key", TransparencyLog.configuration.private_key
  end
end