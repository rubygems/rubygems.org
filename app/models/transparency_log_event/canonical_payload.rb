# frozen_string_literal: true

# Builds the public JSON payload that is signed and submitted to the transparency log.
TransparencyLogEvent::CanonicalPayload = Data.define(:event) do
  def self.from_event(event)
    new(event:)
  end

  def to_h
    corrects_event_uuid = event.corrects_event_uuid
    payload = {
      "specVersion" => event.spec_version,
      "kind" => event.event_type,
      "resource" => resource_payload,
      "actor" => actor_payload,
      "subject" => subject_payload
    }
    payload["gem"] = event.resource_name if event.resource_type == "rubygem"
    payload["corrects"] = corrects_event_uuid if corrects_event_uuid.present?
    payload
  end

  private

  def resource_payload
    resource_id = event.resource_id

    {
      "type" => event.resource_type,
      "name" => event.resource_name
    }.tap do |payload|
      payload["id"] = resource_id if resource_id.present?
    end
  end

  def actor_payload
    actor_id = event.actor_id
    actor_handle = event.actor_handle

    {
      "type" => event.actor_type
    }.tap do |payload|
      payload["id"] = actor_id if actor_id.present?
      payload["handle"] = actor_handle if actor_handle.present?
    end
  end

  def subject_payload
    subject_id = event.subject_id
    subject_handle = event.subject_handle || event.subject_name

    {
      "type" => event.subject_type
    }.tap do |payload|
      payload["id"] = subject_id if subject_id.present?
      payload["handle"] = subject_handle if subject_handle.present?
    end
  end
end
