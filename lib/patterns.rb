module Patterns
  extend ActiveSupport::Concern

  JAVA_HTTP_USER_AGENT  = /^java/i
  SPECIAL_CHARACTERS    = ".-_".freeze
  ALLOWED_CHARACTERS    = "[A-Za-z0-9#{Regexp.escape(SPECIAL_CHARACTERS)}]+".freeze
  ROUTE_PATTERN         = /#{ALLOWED_CHARACTERS}/
  LAZY_ROUTE_PATTERN    = /#{ALLOWED_CHARACTERS}?/
  NAME_PATTERN          = /\A#{ALLOWED_CHARACTERS}\z/
  URL_VALIDATION_REGEXP = %r{\Ahttps?://([^\s:@]+:[^\s:@]*@)?[A-Za-z\d-]+(\.[A-Za-z\d-]+)+\.?(:\d{1,5})?([/?]\S*)?\z}
  VERSION_PATTERN       = /\A#{Gem::Version::VERSION_PATTERN}\z/o
end
