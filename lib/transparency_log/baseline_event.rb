# frozen_string_literal: true

require "digest/sha1"

class TransparencyLog::BaselineEvent
  UUID_NAMESPACE = "91c295e4-2948-4f9b-b238-8bf4a14a26f7"

  def initialize(baseline_id:, observed_at:, recorder: TransparencyLog::Recorder.new)
    @baseline_id = baseline_id
    @observed_at = observed_at
    @recorder = recorder
  end

  def record(event_type:, subject_key:, resource:, subject:, payload_attributes: {})
    event_uuid = self.class.event_uuid(baseline_id: @baseline_id, event_type:, subject_key:)
    existing_event = TransparencyLogEvent.find_by(event_uuid:)
    return existing_event if existing_event

    @recorder.record(
      {
        event_uuid:,
        event_type:,
        baseline_id: @baseline_id,
        observed_at: @observed_at,
        resource_type: resource.fetch(:type),
        resource_name: resource.fetch(:name),
        resource_id: resource[:id],
        subject_type: subject.fetch(:type),
        subject_name: subject.fetch(:name),
        subject_id: subject[:id],
        subject_handle: subject[:handle],
        actor_type: "system",
        actor_id: "rubygems.org",
        authentication_method: "baseline_snapshot",
        payload_attributes:
      },
      enqueue: false
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    TransparencyLogEvent.find_by!(event_uuid:)
  end

  def self.event_uuid(baseline_id:, event_type:, subject_key:)
    name = [baseline_id, event_type, subject_key].join(":")
    namespace = [UUID_NAMESPACE.delete("-")].pack("H*")
    bytes = Digest::SHA1.digest(namespace + name).bytes.first(16)
    bytes[6] = (bytes[6] & 0x0f) | 0x50
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    hex = bytes.pack("C*").unpack1("H*")

    "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
  end
end
