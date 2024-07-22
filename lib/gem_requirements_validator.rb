# frozen_string_literal: true

class GemRequirementsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    return if value.split(", ").all? do |requirement|
                requirement.length < Gemcutter::MAX_FIELD_LENGTH && Patterns::REQUIREMENT_PATTERN.match?(requirement)
              end
    record.errors.add(attribute, "must be list of valid requirements")
  end
end
