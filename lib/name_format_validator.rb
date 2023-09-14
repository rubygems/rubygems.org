# frozen_string_literal: true

class NameFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.class != String
      record.errors.add attribute, "must be a String"
    elsif !Patterns::LETTER_REGEXP.match?(value)
      record.errors.add attribute, "must include at least one letter"
    elsif !Patterns::NAME_PATTERN.match?(value)
      record.errors.add attribute, "can only include letters, numbers, dashes, and underscores"
    elsif Patterns::SPECIAL_CHAR_PREFIX_REGEXP.match?(value)
      record.errors.add attribute, "can not begin with a period, dash, or underscore"
    end
  end
end
