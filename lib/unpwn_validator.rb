require "unpwn"

class UnpwnValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :unpwn) unless unpwn.acceptable?(value)
  rescue Pwned::TimeoutError # rubocop:disable Lint/SuppressedException
    # Do nothing if the HTTP call timesout, consider the value valid
  rescue Pwned::Error # rubocop:disable Lint/SuppressedException
    # Do nothing if the HTTP call fails, consider the value valid
  end

  private

  def unpwn
    @unpwn ||= Unpwn.new(min: nil, max: nil, request_options: { read_timeout: 3 })
  end
end
