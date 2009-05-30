RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.time_zone = 'UTC'

  config.gem 'haml',
    :version => '2.1.0'
  config.gem "thoughtbot-clearance",
    :lib     => 'clearance',
    :source  => 'http://gems.github.com',
    :version => '0.6.6'
  config.gem "thoughtbot-pacecar",
    :lib     => 'pacecar',
    :source  => 'http://gems.github.com',
    :version => '1.1.5'
  config.gem "ismasan-sluggable_finder",
    :lib     => 'sluggable_finder',
    :version => '2.0.6'
end

DO_NOT_REPLY = "donotreply@gemcutter.org"

require 'rubygems'
require 'rubygems/format'
require 'rubygems/indexer'
require 'lib/indexer'

Gem.configuration.verbose = false
