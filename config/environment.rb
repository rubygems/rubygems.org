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
  config.gem 'mislav-will_paginate',
    :version => '~> 2.3.11',
    :lib     => 'will_paginate',
    :source  => 'http://gems.github.com'
  config.gem 'aws-s3',
    :version => '0.6.2',
    :lib     => 'aws/s3'
end

DO_NOT_REPLY = "donotreply@gemcutter.org"

require 'rubygems'
require 'rubygems/format'
require 'rubygems/indexer'
require 'lib/indexer'
require 'lib/core_ext/string'

Gem.configuration.verbose = false

require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/sessions_controller'
require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/passwords_controller'
require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/confirmations_controller'
require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/users_controller'

