# frozen_string_literal: true

require "test_helper"

class TransparencyLog::EntryBuilderTest < ActiveSupport::TestCase
  setup do
    @private_key = OpenSSL::PKey::EC.generate("prime256v1")
    @json_payload = '{"gem":"rack","version":"3.0.0"}'
    @entry = TransparencyLog::EntryBuilder.new(@private_key).build(@json_payload)
  end

  should "build a hashedrekord entry" do
    assert @entry.key?("hashedRekordRequestV002")

    hashed_rekord = @entry["hashedRekordRequestV002"]

    assert_equal(
      Base64.strict_encode64(Digest::SHA256.digest(@json_payload)),
      hashed_rekord["digest"]
    )

    assert_equal(
      "PKIX_ECDSA_P256_SHA_256",
      hashed_rekord.dig("signature", "verifier", "keyDetails")
    )
  end

  should "produce a verifiable signature" do
    signature = Base64.decode64(
      @entry.dig("hashedRekordRequestV002", "signature", "content")
    )

    assert @private_key.verify(
      OpenSSL::Digest.new("SHA256"),
      signature,
      @json_payload
    )
  end

  should "include the public key verifier" do
    raw_bytes = Base64.decode64(
      @entry.dig(
        "hashedRekordRequestV002",
        "signature",
        "verifier",
        "publicKey",
        "rawBytes"
      )
    )

    assert_equal @private_key.public_to_der, raw_bytes
  end
end
