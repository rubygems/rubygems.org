# frozen_string_literal: true

require "test_helper"

class TransparencyLogTest < ActiveSupport::TestCase
  def setup
    @original_rekor_url = TransparencyLog.rekor_url
  end

  def teardown
    TransparencyLog.rekor_url = @original_rekor_url
  end

  test "default value is set correctly" do
    assert_equal "http://localhost:3004", TransparencyLog.rekor_url
  end

  test "rekor_url can be set and retrieved" do
    new_url = "https://rekor.example.com"
    TransparencyLog.rekor_url = new_url

    assert_equal new_url, TransparencyLog.rekor_url
  end
end
