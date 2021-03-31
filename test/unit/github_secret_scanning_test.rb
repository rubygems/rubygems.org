require "test_helper"

class GitHubSecretScanningTest < ActiveSupport::TestCase
  should "return false when empty json" do
    GitHubSecretScanning.stubs(:secret_scanning_keys).returns("{}")
    key = GitHubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")

    GitHubSecretScanning.stubs(:secret_scanning_keys).returns("{\"public_keys\": {}}")
    key = GitHubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")
  end

  should "return false if no public key is found" do
    GitHubSecretScanning.stubs(:secret_scanning_keys).returns("{}")
    key = GitHubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")

    GitHubSecretScanning.stubs(:secret_scanning_keys).returns("{\"public_keys\": {}}")
    key = GitHubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")
  end
end
