# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# See everything in the log (default is :info)
# config.log_level = :debug

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Enable threaded mode
# config.threadsafe!

require "#{RAILS_ROOT}/config/secret" if File.exists?("#{RAILS_ROOT}/config/secret.rb")

HOST = "gemcutter.org"

config.after_initialize do
  require 'aws/s3'
  require 'lib/vault_object'
end

if ENV['MEMCACHE_SERVERS']
  require 'memcache'
  require 'rack/cache'

  memcache_store = MemCache.new(ENV['MEMCACHE_SERVERS'].split(','),
    {:namespace => ENV['MEMCACHE_NAMESPACE']})

  config.middleware.insert_after(::Rack::Lock, ::Rack::Cache,
    :verbose     => true,
    :metastore   => memcache_store,
    :entitystore => memcache_store)
end

