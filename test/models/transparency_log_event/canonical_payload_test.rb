# frozen_string_literal: true

require "test_helper"

# Exercises the public payload builder for signed transparency log entries.
class TransparencyLogEvent::CanonicalPayloadTest < ActiveSupport::TestCase
  should "build the public canonical payload from an event" do
    corrects_event_uuid = SecureRandom.uuid
    event = build(
      :transparency_log_event,
      spec_version: "1.0",
      event_type: "rubygem.owner.added",
      resource_type: "rubygem",
      resource_name: "rack",
      resource_id: "gem-123",
      actor_type: "user",
      actor_id: "100",
      actor_handle: "gem-author",
      subject_type: "user",
      subject_id: "200",
      subject_name: "new-owner",
      subject_handle: "new-owner",
      corrects_event_uuid:
    )

    assert_equal(
      {
        "specVersion" => "1.0",
        "kind" => "rubygem.owner.added",
        "resource" => {
          "type" => "rubygem",
          "name" => "rack",
          "id" => "gem-123"
        },
        "actor" => {
          "type" => "user",
          "id" => "100",
          "handle" => "gem-author"
        },
        "subject" => {
          "type" => "user",
          "id" => "200",
          "handle" => "new-owner"
        },
        "gem" => "rack",
        "corrects" => corrects_event_uuid
      },
      TransparencyLogEvent::CanonicalPayload.from_event(event).to_h
    )
  end
end
