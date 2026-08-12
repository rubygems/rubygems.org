# frozen_string_literal: true

require "test_helper"

class TransparencyLog::BaselineEventTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "derives a deterministic version 5 UUID from the baseline event identity" do
    event_uuid = TransparencyLog::BaselineEvent.event_uuid(
      baseline_id: transparency_log_baseline_attributes.fetch(:baseline_id),
      event_type: "gem.baseline",
      subject_key: "rubygem:123"
    )

    assert_equal event_uuid, TransparencyLog::BaselineEvent.event_uuid(
      baseline_id: transparency_log_baseline_attributes.fetch(:baseline_id),
      event_type: "gem.baseline",
      subject_key: "rubygem:123"
    )
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/, event_uuid)
    refute_equal event_uuid, TransparencyLog::BaselineEvent.event_uuid(
      baseline_id: transparency_log_baseline_attributes.fetch(:baseline_id),
      event_type: "gem.baseline",
      subject_key: "rubygem:124"
    )
  end

  test "records a pending baseline event without enqueueing submission" do
    recorder = TransparencyLog::BaselineEvent.new(**transparency_log_baseline_attributes)
    event = nil

    assert_no_enqueued_jobs only: ProcessTransparencyLogEventJob do
      event = recorder.record(
        event_type: "gem.version.baseline",
        subject_key: "version:456",
        resource: { type: "rubygem", name: "rack", id: "123" },
        subject: { type: "rubygem_version", name: "rack-3.2.0", id: "456" },
        payload_attributes: { "state" => "indexed" }
      )
    end

    assert_predicate event, :pending?
    assert_equal transparency_log_baseline_attributes.fetch(:baseline_id), event.baseline_id
    assert_equal transparency_log_baseline_attributes.fetch(:observed_at), event.observed_at
    assert_equal "system", event.actor_type
    assert_equal "rubygems.org", event.actor_id
    assert_equal "baseline_snapshot", event.authentication_method
    assert_equal({ "state" => "indexed" }, event.payload_attributes)
    assert_equal(
      {
        "id" => transparency_log_baseline_attributes.fetch(:baseline_id),
        "observedAt" => "2026-08-12T01:02:03.000000Z",
        "eventId" => event.event_uuid
      },
      event.canonical_payload.fetch("baseline")
    )
  end

  test "returns the existing event when the same baseline fact is retried" do
    recorder = TransparencyLog::BaselineEvent.new(**transparency_log_baseline_attributes)
    attributes = {
      event_type: "gem.baseline",
      subject_key: "rubygem:123",
      resource: { type: "rubygem", name: "rack", id: "123" },
      subject: { type: "rubygem", name: "rack", id: "123" }
    }

    first = recorder.record(**attributes)

    assert_no_difference "TransparencyLogEvent.count" do
      assert_equal first, recorder.record(**attributes)
    end
  end
end
