module Patterns
  extend ActiveSupport::Concern

  SPECIAL_CHARACTERS    = ".-_".freeze
  ALLOWED_CHARACTERS    = "[A-Za-z0-9#{Regexp.escape(SPECIAL_CHARACTERS)}]+".freeze
  ROUTE_PATTERN         = /#{ALLOWED_CHARACTERS}(?<!\.gem)/
  LAZY_ROUTE_PATTERN    = /#{ALLOWED_CHARACTERS}?/
  NAME_PATTERN          = /\A#{ALLOWED_CHARACTERS}\z/
  LETTER_REGEXP         = /[a-zA-Z]+/
  URL_VALIDATION_REGEXP = %r{\Ahttps?://([^\s:@]+:[^\s:@]*@)?[A-Za-z\d-]+(\.[A-Za-z\d-]+)+\.?(:\d{1,5})?([/?]\S*)?\z}
  VERSION_PATTERN       = /\A#{Gem::Version::VERSION_PATTERN}\z/o
  REQUIREMENT_PATTERN   = Gem::Requirement::PATTERN
  BASE64_SHA256_PATTERN = %r{\A[0-9a-zA-Z_+/-]{43}={0,2}\z}
  HANDLE_PATTERN        = /\A[A-Za-z][A-Za-z_\-0-9]*\z/
  SPECIAL_CHAR_PREFIX_REGEXP = /\A[#{Regexp.escape(SPECIAL_CHARACTERS)}]/o
  SPECIAL_CHAR_SUFFIX_REGEXP = /[#{Regexp.escape(SPECIAL_CHARACTERS)}]\z/o
  BANNED_EXTENSIONS          = %w[gem json html gemspec].freeze
  BANNED_EXTENSION_REGEXP    = /\.(?:#{Regexp.union(BANNED_EXTENSIONS)})\z/i
end
