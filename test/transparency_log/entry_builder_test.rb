# frozen_string_literal: true

require "test_helper"

class TransparencyLog::EntryBuilderTest < ActiveSupport::TestCase
  setup do
    @transparency_log_event = create(:transparency_log_event)
    @entry = TransparencyLog::EntryBuilder.new.build(@transparency_log_event)
  end

  test "build the expected hashedrekord structure" do
    assert_equal(
      {
        "hashedRekordRequestV002" => {
          "digest" => @transparency_log_event.encoded_payload_digest,
          "signature" => {
            "content" => @transparency_log_event.encoded_signature,
            "verifier" => {
              "publicKey" => {
                "rawBytes" => @transparency_log_event.encoded_public_key_der
              },
              "keyDetails" => TransparencyLog::EntryBuilder::KEY_DETAILS
            }
          }
        }
      },
      @entry
    )
  end
end
