# frozen_string_literal: true

require "base64"
require "digest"
require "openssl"

class TransparencyLog::EntryBuilder
  KEY_DETAILS = "PKIX_ECDSA_P256_SHA_256"

  attr_reader :private_key

  def build(transparency_log_event)
    {
      "hashedRekordRequestV002" => {
        # SIGN DIGEST
        "digest" => transparency_log_event.encoded_payload_digest,
        "signature" => {
          "content" => transparency_log_event.encoded_signature,
          "verifier" => {
            "publicKey" => {
              "rawBytes" => transparency_log_event.encoded_public_key_der
            },
            "keyDetails" => KEY_DETAILS
          }
        }
      }
    }
  end
end
