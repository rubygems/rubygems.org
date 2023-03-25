require "test_helper"

class GitHubSecretScanningTest < ActiveSupport::TestCase
  should "return false when empty json" do
    stub_request(:get, GitHubSecretScanning::KEYS_URI)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {}.to_json
      )
    key = GitHubSecretScanning.new("key_id")

    refute key.valid_github_signature?("", "")
  end

  should "return false if no public key is found" do
    stub_request(:get, GitHubSecretScanning::KEYS_URI)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { public_keys: {} }.to_json
      )
    key = GitHubSecretScanning.new("key_id")

    refute key.valid_github_signature?("", "")
  end
end
