# frozen_string_literal: true

require "base64"
require "digest"
require "openssl"

class TransparencyLog::EntryBuilder
  KEY_DETAILS = "PKIX_ECDSA_P256_SHA_256"

  def initialize(private_key)
    @private_key = private_key
  end

  def build(json_payload)
    signature = @private_key.sign(
      OpenSSL::Digest.new("SHA256"),
      json_payload
    )

    {
      "hashedRekordRequestV002" => {
        "digest" => Base64.strict_encode64(
          Digest::SHA256.digest(json_payload)
        ),
        "signature" => {
          "content" => Base64.strict_encode64(signature),
          "verifier" => {
            "publicKey" => {
              "rawBytes" => Base64.strict_encode64(@private_key.public_to_der)
            },
            "keyDetails" => KEY_DETAILS
          }
        }
      }
    }
  end
end
