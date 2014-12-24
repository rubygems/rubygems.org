Gemcutter::Application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.active_support.deprecation = :log
  config.action_mailer.raise_delivery_errors = false
  config.assets.debug = true
  config.assets.raise_runtime_errors = true
end
