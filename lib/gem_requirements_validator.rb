# frozen_string_literal: true

class GemRequirementsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    return if value.split(", ").all? { |requirement| Patterns::REQUIREMENT_PATTERN.match?(requirement) }
    record.errors.add(attribute, "must be list of valid requirements")
  end
end
