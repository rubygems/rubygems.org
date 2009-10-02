RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')
require "#{RAILS_ROOT}/vendor/bundler_gems/environment"

Rails::Initializer.run do |config|
  config.time_zone = 'UTC'
  config.action_mailer.delivery_method = :smtp
end

Bundler.require_env

DO_NOT_REPLY = "donotreply@gemcutter.org"

require 'lib/indexer'
require 'lib/core_ext/string'
require 'clearance/sessions_controller'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

Gem.configuration.verbose = false
ActiveRecord::Base.include_root_in_json = false
