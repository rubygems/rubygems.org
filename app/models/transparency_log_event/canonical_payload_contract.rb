# frozen_string_literal: true

# Validates the public payload fields against the event columns that drive API queries.
TransparencyLogEvent::CanonicalPayloadContract = Data.define(:event) do
  def validate
    validate_payload_fields
    validate_resource
    validate_identity("actor", event.actor_type)
    validate_identity("subject", event.subject_type)
  end

  private

  def validate_payload_fields
    validate_payload_field("specVersion", event.spec_version)
    validate_payload_field("kind", event.event_type)
  end

  def validate_payload_field(field, expected_value)
    value = payload[field]

    errors.add(:canonical_payload, "must include #{field}") if value.blank?
    errors.add(:canonical_payload, "#{field} must match #{expected_value}") if value.present? && value != expected_value
  end

  def validate_resource
    if payload["resource"].is_a?(Hash)
      validate_payload_hash_value("resource", "type", event.resource_type)
      validate_payload_hash_value("resource", "name", event.resource_name)
    else
      validate_gem_resource
    end
  end

  def validate_gem_resource
    gem_name = payload["gem"]
    resource_name = event.resource_name

    if gem_name.present?
      errors.add(:canonical_payload, "gem must match #{resource_name}") unless gem_name == resource_name
    else
      errors.add(:canonical_payload, "must include resource")
    end
  end

  def validate_identity(field, expected_type)
    identity = payload[field]

    unless identity.is_a?(Hash)
      errors.add(:canonical_payload, "must include #{field} as a JSON object")
      return
    end

    validate_payload_hash_value(field, "type", expected_type)
  end

  def validate_payload_hash_value(field, key, expected_value)
    value = payload.dig(field, key)

    errors.add(:canonical_payload, "#{field}.#{key} must match #{expected_value}") if value.blank? || value != expected_value
  end

  def payload
    event.canonical_payload
  end

  def errors
    event.errors
  end
end
