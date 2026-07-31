# frozen_string_literal: true

require "test_helper"

class TransparencyLog::RecorderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @transparency_log_event = build(:transparency_log_event)
    @recorder = TransparencyLog::Recorder.new
  end

  test "signs saves and enqueues transparency log event" do
    assert_enqueued_jobs 1, only: ProcessTransparencyLogEventJob do
      @recorder.record(@transparency_log_event)
    end

    assert_predicate @transparency_log_event, :persisted?

    expected_payload =
      TransparencyLogEvent::CanonicalPayload
        .from_event(@transparency_log_event)
        .to_h

    assert_equal expected_payload, @transparency_log_event.canonical_payload
    assert_predicate @transparency_log_event.payload_digest, :present?
    assert_predicate @transparency_log_event.signature, :present?
    assert_predicate @transparency_log_event.public_key_der, :present?
  end
end
