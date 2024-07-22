require 'rubygems/package'

Gem.load_yaml
raise "Update rubygems to 3.5.7 or greater for Gem::SafeYAML.aliases_enabled= support" unless Gem::SafeYAML.respond_to?(:aliases_enabled=)
Gem::SafeYAML.aliases_enabled = false

Gem::Package.class_eval do
  include SemanticLogger::Loggable
  delegate :warn, to: :logger
end
