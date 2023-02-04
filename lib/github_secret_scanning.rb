class GitHubSecretScanning
  KEYS_URI = "https://api.github.com/meta/public_keys/secret_scanning".freeze

  def initialize(key_identifier)
    @public_key = self.class.public_key(key_identifier)
  end

  def valid_github_signature?(signature, body)
    return false if @public_key.blank?
    openssl_key = OpenSSL::PKey::EC.new(@public_key)
    openssl_key.verify(OpenSSL::Digest.new("SHA256"), Base64.decode64(signature), body)
  end

  def empty_public_key?
    @public_key.blank?
  end

  def self.public_key(id)
    cache_key = ["GitHubSecretScanning", "public_keys", id]
    Rails.cache.fetch(cache_key) do
      public_keys = JSON.parse(secret_scanning_keys)["public_keys"]
      public_keys&.find { |v| v["key_identifier"] == id }&.fetch("key")
    end
  end

  def self.secret_scanning_keys
    RestClient.get(KEYS_URI).body
  end
end
