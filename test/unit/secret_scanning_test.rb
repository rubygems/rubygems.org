# frozen_string_literal: true

require "test_helper"

class SecretScanningTest < ActiveSupport::TestCase
  should "return false when empty json" do
    stub_request(:get, SecretScanning::GitHub::KEYS_URI)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {}.to_json
      )
    key = SecretScanning.new(SecretScanning::GitHub.public_key("key_id"))

    refute key.valid_signature?("", "")
  end

  should "return false if no public key is found" do
    stub_request(:get, SecretScanning::GitHub::KEYS_URI)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { public_keys: {} }.to_json
      )
    key = SecretScanning.new(SecretScanning::GitHub.public_key("key_id"))

    refute key.valid_signature?("", "")
  end
end
