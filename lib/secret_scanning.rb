# frozen_string_literal: true

class SecretScanning
  include SemanticLogger::Loggable

  class AuthenticationError < StandardError; end

  def self.authenticate!(request)
    headers = request.headers
    provider = [GitHub, DepsDev].find do |candidate|
      headers[candidate::IDENTIFIER_HEADER].present? && headers[candidate::SIGNATURE_HEADER].present?
    end

    raise AuthenticationError, "Missing secret scanning signature" unless provider

    key = new(provider.public_key(headers[provider::IDENTIFIER_HEADER]))
    raise AuthenticationError, "Secret scanning public key not found" if key.empty_public_key?

    signature = headers[provider::SIGNATURE_HEADER]
    body = request.body.read
    return if key.valid_signature?(signature, body)

    logger.warn "Invalid secret scanning signature", provider: provider.name, key: key, signature: signature, body: body
    raise AuthenticationError, "Invalid secret scanning signature"
  end

  def initialize(public_key)
    @public_key = public_key
  end

  def valid_signature?(signature, body)
    return false if @public_key.blank?
    openssl_key = OpenSSL::PKey::EC.new(@public_key)
    openssl_key.verify(OpenSSL::Digest.new("SHA256"), Base64.decode64(signature), body)
  end

  def empty_public_key?
    @public_key.blank?
  end

  class PublicKeyList
    def self.public_key(id)
      cache_key = [self::CACHE_NAMESPACE, "public_keys", id]
      Rails.cache.fetch(cache_key) do
        public_keys = secret_scanning_keys.public_keys
        public_keys&.find { |v| v.key_identifier == id }&.key
      end
    end

    def self.secret_scanning_keys
      Octokit.client.get(self::KEYS_URI)
    end
  end

  class GitHub < PublicKeyList
    CONFIG = Rails.configuration.secret_scanning.fetch(:github)
    IDENTIFIER_HEADER = CONFIG.fetch(:identifier_header).freeze
    SIGNATURE_HEADER = CONFIG.fetch(:signature_header).freeze
    KEYS_URI = CONFIG.fetch(:keys_uri).freeze
    CACHE_NAMESPACE = CONFIG.fetch(:cache_namespace).freeze
  end

  class DepsDev < PublicKeyList
    CONFIG = Rails.configuration.secret_scanning.fetch(:deps_dev)
    IDENTIFIER_HEADER = CONFIG.fetch(:identifier_header).freeze
    SIGNATURE_HEADER = CONFIG.fetch(:signature_header).freeze
    KEYS_URI = CONFIG.fetch(:keys_uri).freeze
    CACHE_NAMESPACE = CONFIG.fetch(:cache_namespace).freeze
  end
end
