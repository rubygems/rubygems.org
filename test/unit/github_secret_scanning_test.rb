require "test_helper"

class GithubSecretScanningTest < ActiveSupport::TestCase
  should "return false when empty json" do
    GithubSecretScanning.stubs(:secret_scanning_keys).returns("{}")
    key = GithubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")

    GithubSecretScanning.stubs(:secret_scanning_keys).returns("{\"public_keys\": {}}")
    key = GithubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")
  end

  should "return false if no public key is found" do
    GithubSecretScanning.stubs(:secret_scanning_keys).returns("{}")
    key = GithubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")

    GithubSecretScanning.stubs(:secret_scanning_keys).returns("{\"public_keys\": {}}")
    key = GithubSecretScanning.new("key_id")
    refute key.valid_github_signature?("", "")
  end
end
