class HttpUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    uri = URI::DEFAULT_PARSER.parse(value)
    record.errors.add attribute, "is not a valid URL" unless [URI::HTTP, URI::HTTPS].member?(uri.class)
  rescue URI::InvalidURIError
    record.errors.add attribute, "is not a valid URL"
  end
end
