RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.time_zone = 'UTC'
  config.action_mailer.delivery_method = :smtp
  config.frameworks -= [:active_resource]
end

DO_NOT_REPLY = "donotreply@gemcutter.org"

require 'lib/rubygems/format'
require 'lib/rubygems/indexer'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'
require 'clearance/sessions_controller'

Gem.configuration.verbose = false
ActiveRecord::Base.include_root_in_json = false
