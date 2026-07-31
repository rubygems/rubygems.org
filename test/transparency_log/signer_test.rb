# frozen_string_literal: true

require "test_helper"

class TransparencyLog::SignerTest < ActiveSupport::TestCase
  setup do
    @transparency_log_event = create(:transparency_log_event)
    @signer = TransparencyLog::Signer.new
    @private_key = OpenSSL::PKey.read(
      TransparencyLog.configuration.private_key
    )
  end

  test "signs transparency log event canonical payload" do
    result = @signer.sign(@transparency_log_event.canonical_payload)
    payload = @transparency_log_event.canonical_payload.to_json

    assert_equal Digest::SHA256.digest(payload), result[:payload_digest]
    assert_equal @private_key.public_to_der, result[:public_key_der]

    assert @private_key.verify(
      OpenSSL::Digest.new("SHA256"),
      result[:signature],
      payload
    )
  end
end
