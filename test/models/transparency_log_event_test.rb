# frozen_string_literal: true

require "test_helper"

# Exercises the model-level invariants for transparency log events.
class TransparencyLogEventTest < ActiveSupport::TestCase
  subject { build(:transparency_log_event) }

  should define_enum_for(:status)
    .with_values(TransparencyLogEvent::STATUSES)
    .backed_by_column_of_type(:string)

  should validate_presence_of(:event_type)
  should validate_presence_of(:resource_type)
  should validate_presence_of(:resource_name)
  should validate_presence_of(:spec_version)
  should validate_presence_of(:subject_type)
  should validate_presence_of(:subject_name)
  should validate_presence_of(:actor_type)
  should validate_presence_of(:actor_id)
  should validate_presence_of(:authentication_method)
  should validate_presence_of(:canonical_payload)
  should validate_presence_of(:canonicalization_algorithm)
  should validate_presence_of(:canonicalization_version)
  should validate_presence_of(:payload_digest_algorithm)
  should validate_presence_of(:payload_digest)
  should validate_presence_of(:signing_mode)
  should validate_presence_of(:signing_key_id)
  should validate_presence_of(:signing_algorithm)
  should validate_presence_of(:signature)
  should validate_presence_of(:public_key_id)
  should validate_presence_of(:public_key_der)
  should validate_presence_of(:rekor_request_body)

  should validate_uniqueness_of(:event_uuid).ignoring_case_sensitivity
  should validate_uniqueness_of(:payload_digest).scoped_to(:payload_digest_algorithm)
  should validate_numericality_of(:attempt_count).only_integer.is_greater_than_or_equal_to(0)

  should "require event uuid once persisted" do
    event = create(:transparency_log_event)
    event.event_uuid = nil

    refute_predicate event, :valid?
    assert_includes event.errors[:event_uuid], "can't be blank"
  end

  should "assign an event uuid on create" do
    event = create(:transparency_log_event)

    assert_match(/\A[0-9a-f-]{36}\z/, event.event_uuid)
  end

  should "preserve a provided event uuid" do
    event_uuid = SecureRandom.uuid

    event = create(:transparency_log_event, event_uuid:)

    assert_equal event_uuid, event.event_uuid
  end

  should "require canonical payload to be a JSON object" do
    event = build(:transparency_log_event, canonical_payload: %w[not an object])

    refute_predicate event, :valid?
    assert_includes event.errors[:canonical_payload], "must be a JSON object"
  end

  should "require canonical payload to include the event contract fields" do
    event = build(:transparency_log_event, canonical_payload: {})

    refute_predicate event, :valid?
    assert_includes event.errors[:canonical_payload], "must include specVersion"
    assert_includes event.errors[:canonical_payload], "must include kind"
    assert_includes event.errors[:canonical_payload], "must include resource"
    assert_includes event.errors[:canonical_payload], "must include actor as a JSON object"
    assert_includes event.errors[:canonical_payload], "must include subject as a JSON object"
  end

  should "require canonical payload contract fields to match event attributes" do
    event = build(
      :transparency_log_event,
      spec_version: "1.0",
      event_type: "rubygem.owner.added",
      resource_type: "rubygem",
      resource_name: "rack",
      canonical_payload: {
        "specVersion" => "2.0",
        "kind" => "rubygem.owner.removed",
        "resource" => { "type" => "organization", "name" => "rails" },
        "actor" => { "type" => "api_key" },
        "subject" => { "type" => "organization" }
      }
    )

    refute_predicate event, :valid?
    assert_includes event.errors[:canonical_payload], "specVersion must match 1.0"
    assert_includes event.errors[:canonical_payload], "kind must match rubygem.owner.added"
    assert_includes event.errors[:canonical_payload], "resource.type must match rubygem"
    assert_includes event.errors[:canonical_payload], "resource.name must match rack"
    assert_includes event.errors[:canonical_payload], "actor.type must match user"
    assert_includes event.errors[:canonical_payload], "subject.type must match user"
  end

  should "allow canonical payloads to identify rubygem resources with the RFC gem field" do
    event = build(
      :transparency_log_event,
      resource_name: "rack",
      canonical_payload: {
        "specVersion" => "1.0",
        "kind" => "rubygem.owner.added",
        "gem" => "rack",
        "actor" => { "type" => "user" },
        "subject" => { "type" => "user" }
      }
    )

    assert_predicate event, :valid?
  end

  should "require Rekor request body to be a JSON object" do
    event = build(:transparency_log_event, rekor_request_body: %w[not an object])

    refute_predicate event, :valid?
    assert_includes event.errors[:rekor_request_body], "must be a JSON object"
  end

  should "require Rekor response details when submitted" do
    event = build(:transparency_log_event, status: :submitted)

    refute_predicate event, :valid?
    assert_includes event.errors[:rekor_response_body], "can't be blank"
    assert_includes event.errors[:rekor_log_origin], "can't be blank"
    assert_includes event.errors[:rekor_entry_kind], "can't be blank"
    assert_includes event.errors[:rekor_entry_version], "can't be blank"
    assert_includes event.errors[:rekor_log_index], "can't be blank"
    assert_includes event.errors[:rekor_submitted_at], "can't be blank"
  end

  should "require an error when failed" do
    event = build(:transparency_log_event, status: :failed, last_error: nil)

    refute_predicate event, :valid?
    assert_includes event.errors[:last_error], "can't be blank"
  end

  should "reject negative Rekor log indexes" do
    event = build(:transparency_log_event, :submitted, rekor_log_index: -1)

    refute_predicate event, :valid?
    assert_includes event.errors[:rekor_log_index], "must be greater than or equal to 0"
  end

  should "encode binary values as base64" do
    event = build(
      :transparency_log_event,
      payload_digest: Digest::SHA256.digest("payload"),
      signature: "signature",
      public_key_der: "public key"
    )

    assert_equal Base64.strict_encode64(Digest::SHA256.digest("payload")), event.encoded_payload_digest
    assert_equal Base64.strict_encode64("signature"), event.encoded_signature
    assert_equal Base64.strict_encode64("public key"), event.encoded_public_key_der
  end

  should "return stable subject and actor labels" do
    event = build(
      :transparency_log_event,
      resource_type: "rubygem",
      resource_name: "rack",
      subject_type: "rubygem_version",
      subject_name: "rack-3.0.0",
      actor_type: "user",
      actor_id: "123",
      actor_handle: "gem-author"
    )

    assert_equal "rubygem:rack", event.resource
    assert_equal "rubygem_version:rack-3.0.0", event.subject
    assert_equal "gem-author", event.actor
  end

  should "fall back to actor type and id without a handle" do
    event = build(:transparency_log_event, actor_type: "api_key", actor_id: "key-123", actor_handle: nil)

    assert_equal "api_key:key-123", event.actor
  end

  should "find events by payload digest" do
    event = create(:transparency_log_event)

    assert_equal event, TransparencyLogEvent.find_by_digest(event.payload_digest_algorithm, event.payload_digest)
  end

  should "scope events by resource" do
    matching = create(:transparency_log_event, resource_name: "rack")
    create(:transparency_log_event, resource_name: "rails")

    assert_equal [matching], TransparencyLogEvent.for_resource("rubygem", "rack")
  end

  should "scope events by event type" do
    matching = create(:transparency_log_event, event_type: "rubygem.owner.added")
    create(:transparency_log_event, event_type: "rubygem.owner.removed")

    assert_equal [matching], TransparencyLogEvent.of_event_type("rubygem.owner.added")
  end

  should "scope events by actor id and handle" do
    matching = create(:transparency_log_event, actor_id: "123", actor_handle: "gem-author")
    create(:transparency_log_event, actor_id: "456", actor_handle: "other-author")

    assert_equal [matching], TransparencyLogEvent.by_actor(type: "user", id: "123")
    assert_equal [matching], TransparencyLogEvent.by_actor(type: "user", handle: "gem-author")
    assert_equal [matching], TransparencyLogEvent.by_actor(type: "user", id: "123", handle: "gem-author")
  end

  should "scope events by creation range" do
    inside = create(:transparency_log_event, created_at: 2.days.ago)
    create(:transparency_log_event, created_at: 4.days.ago)

    assert_equal [inside], TransparencyLogEvent.created_between(3.days.ago, 1.day.ago)
  end

  should "report pending submission health" do
    oldest = create(:transparency_log_event, created_at: 4.minutes.ago)
    create(:transparency_log_event, created_at: 2.minutes.ago)
    submitted = create(:transparency_log_event, :submitted, rekor_submitted_at: 1.minute.ago)
    health = TransparencyLogEvent.submission_health

    assert_equal oldest, health.oldest_pending_event
    assert_equal submitted, health.latest_submitted_event
    assert_equal 2, health.pending_submission_count
    assert_in_delta 4.minutes, health.submission_lag(now: Time.current), 1.second
  end

  should "scope stale pending submissions" do
    stale = create(:transparency_log_event, created_at: 31.minutes.ago)
    create(:transparency_log_event, created_at: 5.minutes.ago)

    assert_equal [stale], TransparencyLogEvent.stale_pending_submission(older_than: 30.minutes.ago)
  end

  should "return no submission lag without pending events" do
    create(:transparency_log_event, :submitted)

    assert_equal 0.seconds, TransparencyLogEvent.submission_health.submission_lag
  end

  should "prevent event content from changing after creation" do
    event = create(:transparency_log_event)
    event.resource_name = "rails"

    refute event.save
    assert_includes event.errors[:resource_name], "cannot be changed after creation"
  end

  should "allow operational submission fields to change after creation" do
    event = create(:transparency_log_event)

    assert event.record_failure(RuntimeError.new("Rekor unavailable"))

    assert_predicate event, :failed?
    assert_equal "Rekor unavailable", event.last_error
  end

  should "record a successful Rekor submission" do
    event = create(:transparency_log_event, last_error: "previous error")
    submitted_at = Time.zone.local(2026, 6, 16, 12, 0, 0)
    response_body = { "uuid" => "rekor-entry-uuid" }
    inclusion_proof = { "treeSize" => 2, "hashes" => ["abc"] }
    rekor_entry = TransparencyLogEvent::RekorEntry.new(
      response_body:,
      origin: "rekor.sigstore.dev",
      kind: "hashedrekord",
      version: "0.0.1",
      index: 123,
      checkpoint: "checkpoint",
      inclusion_proof:
    )

    assert event.record_submission(
      response_body:,
      rekor_entry:,
      submitted_at:
    )

    event.reload

    assert_predicate event, :submitted?
    assert_equal response_body, event.rekor_response_body
    assert_equal "rekor.sigstore.dev", event.rekor_log_origin
    assert_equal "hashedrekord", event.rekor_entry_kind
    assert_equal "0.0.1", event.rekor_entry_version
    assert_equal 123, event.rekor_log_index
    assert_equal "checkpoint", event.rekor_checkpoint
    assert_equal inclusion_proof, event.rekor_inclusion_proof
    assert_equal submitted_at, event.rekor_submitted_at
    assert_nil event.last_error
  end

  should "not record a submission for a failed event" do
    event = create(:transparency_log_event, :failed)
    rekor_entry = TransparencyLogEvent::RekorEntry.new(
      response_body: { "uuid" => "rekor-entry-uuid" },
      origin: "rekor.sigstore.dev",
      kind: "hashedrekord",
      version: "0.0.1",
      index: 123,
      checkpoint: "checkpoint",
      inclusion_proof: {}
    )

    refute event.record_submission(response_body: { "uuid" => "rekor-entry-uuid" }, rekor_entry:)
    assert_includes event.errors[:status], "cannot transition from failed to submitted"

    event.reload

    assert_predicate event, :failed?
    assert_nil event.rekor_log_index
  end

  should "record a submission from an explicitly mapped Rekor entry" do
    event = create(:transparency_log_event)
    response_body = {
      "uuid" => "rekor-entry-uuid",
      "logIndex" => 123,
      "kindVersion" => { "kind" => "hashedrekord", "version" => "0.0.1" },
      "inclusionProof" => {
        "treeSize" => 2,
        "hashes" => ["abc"],
        "checkpoint" => { "envelope" => "checkpoint envelope" }
      }
    }
    rekor_entry = TransparencyLogEvent::RekorEntry.new(
      response_body:,
      origin: "rekor.sigstore.dev",
      kind: response_body.dig("kindVersion", "kind"),
      version: response_body.dig("kindVersion", "version"),
      index: response_body["logIndex"],
      checkpoint: response_body.dig("inclusionProof", "checkpoint", "envelope"),
      inclusion_proof: response_body["inclusionProof"]
    )

    assert event.record_submission(
      response_body:,
      rekor_entry:
    )

    event.reload

    assert_predicate event, :submitted?
    assert_equal "rekor.sigstore.dev", event.rekor_log_origin
    assert_equal "hashedrekord", event.rekor_entry_kind
    assert_equal "0.0.1", event.rekor_entry_version
    assert_equal 123, event.rekor_log_index
    assert_equal "checkpoint envelope", event.rekor_checkpoint
    assert_equal response_body["inclusionProof"], event.rekor_inclusion_proof
  end

  should "record a failed submission attempt" do
    event = create(:transparency_log_event)

    assert event.record_failure(RuntimeError.new("Rekor unavailable"))

    assert_predicate event, :failed?
    assert_equal 1, event.attempt_count
    assert_equal "Rekor unavailable", event.last_error
  end

  should "not record failure after submission" do
    event = create(:transparency_log_event, :submitted, attempt_count: 2)

    refute event.record_failure(RuntimeError.new("Rekor unavailable"))

    assert_includes event.errors[:status], "cannot transition from submitted to failed"
    assert_predicate event, :submitted?
    assert_equal 2, event.attempt_count
  end

  should "increment failed attempts from the locked database value" do
    event = create(:transparency_log_event, attempt_count: 2)
    event.update_column(:attempt_count, 5)

    assert event.record_failure(RuntimeError.new("Rekor unavailable"))

    assert_equal 6, event.attempt_count
  end

  should "retry a failed event without clearing attempt history" do
    event = create(:transparency_log_event, :failed, attempt_count: 3)

    assert event.retry_submission

    assert_predicate event, :pending?
    assert_equal 3, event.attempt_count
    assert_nil event.last_error
  end

  should "not retry an event that has not failed" do
    event = create(:transparency_log_event)

    refute event.retry_submission

    assert_includes event.errors[:status], "cannot transition from pending to pending"
    assert_predicate event, :pending?
  end
end
