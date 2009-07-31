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
  config.gem "ambethia-smtp-tls",
    :lib => "smtp-tls",
    :version => "1.1.2",
    :source => "http://gems.github.com"

  config.action_mailer.delivery_method = :smtp
end

DO_NOT_REPLY = "donotreply@gemcutter.org"

#silence_warnings do
#  require 'lib/rubygems'
#  require 'lib/rubygems/format'
#  require 'lib/rubygems/indexer'
#  require 'lib/rubygems/platform'
#  require 'lib/rubygems/source_index'
#  require 'lib/rubygems/version'
  require 'lib/indexer'
  require 'lib/core_ext/string'
#end

Gem.configuration.verbose = false

require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/sessions_controller'
require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/passwords_controller'
require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/confirmations_controller'
require 'vendor/gems/thoughtbot-clearance-0.6.6/app/controllers/clearance/users_controller'

