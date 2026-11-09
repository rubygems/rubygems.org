# frozen_string_literal: true

require "test_helper"

class SecretScanningTest < ActiveSupport::TestCase
  should "trust only the documented Truffle P-256 public key identifier" do
    identifier = "182a7a4194659dcc955a2ab54709183843504dcfd2ba9b7a68e8207b2b1df9a5"
    key = OpenSSL::PKey::EC.new(SecretScanning::Truffle.public_key(identifier))

    assert_equal "prime256v1", key.group.curve_name
    assert_equal identifier, Digest::SHA256.hexdigest(key.public_to_der)
    assert_nil SecretScanning::Truffle.public_key("untrusted")
  end

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
