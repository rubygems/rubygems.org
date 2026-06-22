# frozen_string_literal: true

class TransparencyLog::TlogEntryBuilder
  def initialize(private_key)
    @private_key = private_key
  end

  def build(json_payload)
    signature = @private_key.sign(
      OpenSSL::Digest.new("SHA256"),
      json_payload
    )

    {
      apiVersion: "0.0.2",
      kind: "hashedrekord",
      spec: {
        hashedRekordV002: {
          data: {
            algorithm: "SHA2_256",
            digest: Base64.strict_encode64(
              Digest::SHA256.digest(json_payload)
            )
          },
          signature: {
            content: Base64.strict_encode64(signature)
          }
        }
      }
    }
  end
end
