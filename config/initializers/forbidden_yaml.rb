# XXX: This is purely a monkey patch to close the exploit vector for now, a more
# permanent solution should be pushed upstream into rubygems.

require "rubygems"
require "rubygems/package"

# Assert we're using Psych
abort "Use Psych for YAML, install libyaml and reinstall ruby" unless YAML == Psych

module Gem
  class Specification
    ALLOWED_CLASSES = %w(
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

    ALLOWED_SYMBOLS = %w(
      development
      runtime
    )

    def self.from_yaml(input)
      input = normalize_yaml_input input
      spec = Psych.safe_load(
        input,
        permitted_classes: ALLOWED_CLASSES,
        permitted_symbols: ALLOWED_SYMBOLS,
        aliases: true
      )

      fail Gem::EndOfYAMLException if spec && spec.class == FalseClass

      unless Gem::Specification === spec
        fail Gem::Exception, "YAML data doesn't evaluate to gem specification"
      end

      spec.specification_version ||= NONEXISTENT_SPECIFICATION_VERSION
      spec.reset_nil_attributes_to_default

      spec
    end
  end
  class Package
    def read_checksums gem
      Gem.load_yaml

      @checksums = gem.seek 'checksums.yaml.gz' do |entry|
        Zlib::GzipReader.wrap entry do |gz_io|
          Psych.safe_load(
            gz_io.read,
            permitted_classes: Gem::Specification::ALLOWED_CLASSES,
            permitted_symbols: Gem::Specification::ALLOWED_SYMBOLS,
            aliases: true
          )
        end
      end
    end
  end
end
