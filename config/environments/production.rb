config.cache_classes = true

config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

require Rails.root.join("config", "secret") if Rails.root.join("config", "secret.rb").file?

HOST = "gemcutter.org"

memcache_store = MemCache.new("localhost:11211", {:namespace => "_gemcutter_production"})
config.middleware.insert_after(::Rack::Lock, ::Rack::Cache,
  :verbose     => true,
  :metastore   => memcache_store,
  :entitystore => memcache_store)
