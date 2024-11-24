class HttpUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    validUriPattern = %r{\Ahttps?://([^\s:@]+:[^\s:@]*@)?[A-Za-z\d\-]+(\.[A-Za-z\d\-]+)+\.?(:\d{1,5})?([\/?]\S*)?\z} # :nodoc:

    uri = URI::DEFAULT_PARSER.parse(value)
    record.errors.add attribute, "is not a valid URL" unless [URI::HTTP, URI::HTTPS].member?(uri.class) && validUriPattern.match?(value)
  rescue URI::InvalidURIError
    record.errors.add attribute, ("is not a valid URL")
  end
end
