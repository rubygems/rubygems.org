# frozen_string_literal: true

# Prevents signed event content from changing after a transparency log event is created.
TransparencyLogEvent::ImmutableEventContent = Data.define(:event) do
  def validate
    changed_immutable_attributes.each do |attribute|
      event.errors.add(attribute, "cannot be changed after creation")
    end
  end

  private

  def changed_immutable_attributes
    event.changed & TransparencyLogEvent::IMMUTABLE_EVENT_ATTRIBUTES
  end
end
