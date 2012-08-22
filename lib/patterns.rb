module Patterns
  extend ActiveSupport::Concern

  SPECIAL_CHARACTERS  = ".-_"
  ALLOWED_CHARACTERS  = "[A-Za-z0-9#{Regexp.escape(SPECIAL_CHARACTERS)}]+"
  ROUTE_PATTERN       = /#{ALLOWED_CHARACTERS}/
  LAZY_ROUTE_PATTERN  = /#{ALLOWED_CHARACTERS}?/
  NAME_PATTERN        = /\A#{ALLOWED_CHARACTERS}\Z/
  CREATE_NAME_PATTERN = /\A[a-z0-9#{Regexp.escape(SPECIAL_CHARACTERS)}]+\Z/
end
