# frozen_string_literal: true

class TransparencyLog::Recorder
  def initialize
    @signer = TransparencyLog::Signer.new
    @entry_builder = TransparencyLog::EntryBuilder.new
  end

  def record(attributes, enqueue: true)
    event = TransparencyLogEvent.new(attributes)

    event.assign_attributes(
      spec_version: "1.0",
      canonicalization_algorithm: "JCS",
      canonicalization_version: "1",
      signing_mode: "server"
    )

    canonical_payload =
      TransparencyLogEvent::CanonicalPayload.from_event(event).to_h

    event.canonical_payload = canonical_payload
    event.assign_attributes(@signer.sign(canonical_payload))
    event.rekor_request_body = @entry_builder.build(event)

    event.save!
    ProcessTransparencyLogEventJob.perform_later(event) if enqueue
    event
  end
end
