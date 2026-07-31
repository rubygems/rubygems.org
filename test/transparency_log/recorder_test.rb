# frozen_string_literal: true

require "test_helper"

class TransparencyLog::RecorderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @transparency_log_event = build(:transparency_log_event)
    @recorder = TransparencyLog::Recorder.new
  end

  test "prepares saves and enqueues transparency log event" do
    assert_enqueued_jobs 1, only: ProcessTransparencyLogEventJob do
      @recorder.record(@transparency_log_event)
    end

    @transparency_log_event.reload

    expected_payload =
      TransparencyLogEvent::CanonicalPayload
        .from_event(@transparency_log_event)
        .to_h

    expected_request =
      TransparencyLog::EntryBuilder.new.build(@transparency_log_event)

    assert_predicate @transparency_log_event, :persisted?
    assert_predicate @transparency_log_event, :valid?

    assert_equal "1.0", @transparency_log_event.spec_version
    assert_equal "JCS", @transparency_log_event.canonicalization_algorithm
    assert_equal "1", @transparency_log_event.canonicalization_version
    assert_equal "server", @transparency_log_event.signing_mode

    assert_equal expected_payload, @transparency_log_event.canonical_payload
    assert_equal expected_request, @transparency_log_event.rekor_request_body

    assert_predicate @transparency_log_event.payload_digest, :present?
    assert_predicate @transparency_log_event.signature, :present?
    assert_predicate @transparency_log_event.public_key_der, :present?

    assert_nil @transparency_log_event.rekor_response_body
  end
end