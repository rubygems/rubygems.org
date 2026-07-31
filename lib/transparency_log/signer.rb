# frozen_string_literal: true

require "digest"
require "openssl"

class TransparencyLog::Signer
  DIGEST_ALGORITHM = "SHA-256"
  SIGNING_ALGORITHM = "ECDSA-P256-SHA256"

  def initialize
    @private_key = OpenSSL::PKey.read(
      TransparencyLog.configuration.private_key
    )
  end

  def sign(canonical_payload)
    payload = canonical_payload.to_json

    {
      payload_digest: Digest::SHA256.digest(payload),
      payload_digest_algorithm: DIGEST_ALGORITHM,
      signature: @private_key.sign(OpenSSL::Digest.new("SHA256"), payload),
      signing_algorithm: SIGNING_ALGORITHM,
      public_key_der: @private_key.public_to_der
    }
  end
end
