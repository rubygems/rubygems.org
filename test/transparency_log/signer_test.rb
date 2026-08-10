# frozen_string_literal: true

require "test_helper"

class TransparencyLog::SignerTest < ActiveSupport::TestCase
  setup do
    @transparency_log_event = build(:transparency_log_event, :canonicalized)
    @signer = TransparencyLog::Signer.new
    @private_key = OpenSSL::PKey.read(
      TransparencyLog.configuration.private_key
    )
  end

  test "signs transparency log event canonical payload" do
    result = @signer.sign(@transparency_log_event.canonical_payload)
    payload = @transparency_log_event.canonical_payload.to_json
    public_key_der = @private_key.public_to_der

    assert_equal Digest::SHA256.digest(payload), result[:payload_digest]
    assert_equal "SHA-256", result[:payload_digest_algorithm]
    assert_equal "ECDSA-P256-SHA256", result[:signing_algorithm]
    assert_equal public_key_der, result[:public_key_der]
    assert_equal Digest::SHA256.hexdigest(public_key_der), result[:public_key_id]

    assert @private_key.verify(
      OpenSSL::Digest.new("SHA256"),
      result[:signature],
      payload
    )
  end
end
