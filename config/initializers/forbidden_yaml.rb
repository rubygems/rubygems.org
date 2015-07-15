# XXX: This is purely a monkey patch to close the exploit vector for now, a more
# permanent solution should be pushed upstream into rubygems.

require "rubygems"

# Assert we're using Psych
abort "Use Psych for YAML, install libyaml and reinstall ruby" unless YAML == Psych

module Gem
  class Specification
    WHITELISTED_CLASSES = %w(
      Symbol
      Time
      Date
      Gem::Dependency
      Gem::Platform
      Gem::Requirement
      Gem::Specification
      Gem::Version
      Gem::Version::Requirement
    )

    WHITELISTED_SYMBOLS = %w(
      development
      runtime
    )

    def self.from_yaml(input)
      input = normalize_yaml_input input
      spec = Psych.safe_load(input, WHITELISTED_CLASSES, WHITELISTED_SYMBOLS, true)

      if spec && spec.class == FalseClass then
        raise Gem::EndOfYAMLException
      end

      unless Gem::Specification === spec then
        raise Gem::Exception, "YAML data doesn't evaluate to gem specification"
      end

      spec.specification_version ||= NONEXISTENT_SPECIFICATION_VERSION
      spec.reset_nil_attributes_to_default

      spec
    end
  end
end
