# frozen_string_literal: true

class NameFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return record.errors.add attribute, "must be a String" if value.class != String

    record.errors.add attribute, "must include at least one letter" if requires_letter? && !Patterns::LETTER_REGEXP.match?(value)
    record.errors.add attribute, "can only include letters, numbers, dashes, and underscores" unless Patterns::NAME_PATTERN.match?(value)
    record.errors.add attribute, "can not begin with a period, dash, or underscore" if Patterns::SPECIAL_CHAR_PREFIX_REGEXP.match?(value)
    record.errors.add attribute, "can not end with a period, dash, or underscore" if Patterns::SPECIAL_CHAR_SUFFIX_REGEXP.match?(value)
    record.errors.add attribute, "can not end with a common file extension" if Patterns::BANNED_EXTENSION_REGEXP.match?(value)
  end

  private

  def requires_letter?
    options.fetch(:requires_letter, true)
  end
end
