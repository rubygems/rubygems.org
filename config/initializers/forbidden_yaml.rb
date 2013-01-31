# XXX: This is purely a monkey patch to close the exploit vector for now, a more
# permanent solution should be pushed upstream into rubygems.

require "rubygems"

# Assert we're using Psych
abort "Use Psych for YAML, install libyaml and reinstall ruby" unless YAML == Psych

module Psych
  class ForbiddenClassException < Exception
  end

  module Visitors
    class WhitelistedToRuby < ToRuby
      WHITELIST = %w(
        Gem::Dependency
        Gem::Platform
        Gem::Requirement
        Gem::Specification
        Gem::Version
        Gem::Version::Requirement
      )

    private

      def resolve_class klassname
        raise ForbiddenClassException, "Forbidden class in YAML: #{klassname}" unless WHITELIST.include? klassname
        super klassname
      end
    end
  end
end

module Gem
  class Specification
    def self.from_yaml input
      input = normalize_yaml_input input
      nodes = Psych.parse input
      spec = Psych::Visitors::WhitelistedToRuby.new.accept nodes

      if spec && spec.class == FalseClass then
        raise Gem::EndOfYAMLException
      end

      unless Gem::Specification === spec then
        raise Gem::Exception, "YAML data doesn't evaluate to gem specification"
      end

      unless (spec.instance_variables.include? '@specification_version' or
              spec.instance_variables.include? :@specification_version) and
             spec.instance_variable_get :@specification_version
        spec.instance_variable_set :@specification_version,
                                   NONEXISTENT_SPECIFICATION_VERSION
      end

      spec
    end
  end
end
