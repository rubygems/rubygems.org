# frozen_string_literal: true

require "test_helper"

class TransparencyLog::EntryBuilderTest < ActiveSupport::TestCase
  setup do
    @transparency_log_event = create(:transparency_log_event)
    @entry = TransparencyLog::EntryBuilder.new.build(@transparency_log_event)
  end

  should "build a hashedrekord entry" do
    assert @entry.key?("hashedRekordRequestV002")

    hashed_rekord = @entry["hashedRekordRequestV002"]

    assert_equal(
      @transparency_log_event.encoded_payload_digest,
      hashed_rekord["digest"]
    )

    assert_equal(
      "PKIX_ECDSA_P256_SHA_256",
      hashed_rekord.dig("signature", "verifier", "keyDetails")
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

    assert_equal @transparency_log_event.public_key_der, raw_bytes
  end
end
