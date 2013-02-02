# XXX: This is purely a monkey patch to close the exploit vector for now, a more
# permanent solution should be pushed upstream into rubygems.

require "rubygems"

# Assert we're using Psych
abort "Use Psych for YAML, install libyaml and reinstall ruby" unless YAML == Psych

module Psych
  class WhitelistException < Exception; end
  class ForbiddenClassException < WhitelistException; end
  class ForbiddenSymbolException < WhitelistException; end

  WHITELISTED_CLASSES = %w(
    Gem::Dependency
    Gem::Platform
    Gem::Requirement
    Gem::Specification
    Gem::Version
    Gem::Version::Requirement
  )

  # These are all unique symbols used across all currently published gems' metadata
  WHITELISTED_SYMBOLS = %w(
    development
    json
    mocha
    rdoc
    runtime
  )

  class WhitelistedScalarScanner < ScalarScanner
    def tokenize string
      # Protect against scanned scalars which will become symbols
      if string[/^:./]
        symbol = string.sub(/^:/, "")
        symbol = $2 if string =~ /^(["'])(.*)\1/

        raise ForbiddenSymbolException, "Forbidden symbol in YAML: #{symbol}" unless WHITELISTED_SYMBOLS.include? symbol
      end

      super
    end
  end

  module Visitors
    class WhitelistedToRuby < ToRuby
      def initialize
        super
        @ss = WhitelistedScalarScanner.new
      end

      def visit_Psych_Nodes_Scalar o
        # Protect against explicitly tagged ruby classes which take the YAML shortcut, i.e. ActiveRecord::Base
        if klass = Psych.load_tags[o.tag]
          raise ForbiddenClassException, "Forbidden class in YAML: #{klassname}" unless WHITELISTED_CLASSES.include? klass.name
        end

        # Protect against explicitly tagged ruby symbols
        if o.tag and o.tag[/^!ruby\/sym(bol)?:?(.*)?$/]
          raise ForbiddenSymbolException, "Forbidden symbol in YAML: #{o.value}" unless WHITELISTED_SYMBOLS.include? o.value
        end

        super
      end

    private

      def resolve_class klassname
        # Protect against all explicit ruby classes, from tags or otherwise
        raise ForbiddenClassException, "Forbidden class in YAML: #{klassname}" unless WHITELISTED_CLASSES.include? klassname

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
