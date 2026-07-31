# frozen_string_literal: true

class TransparencyLog::Recorder
  def initialize
    @signer = TransparencyLog::Signer.new
  end

  def record(event)
    canonical_payload = TransparencyLogEvent::CanonicalPayload.from_event(event).to_h

    event.canonical_payload = canonical_payload
    event.assign_attributes(@signer.sign(canonical_payload))
    event.save!

    ProcessTransparencyLogEventJob.perform_later(event)
  end
end
