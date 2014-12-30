Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.action_mailer.delivery_method = :test
end

ENV['S3_KEY']    = 'this:is:an:ex:parrot'
ENV['S3_SECRET'] = 'it:has:ceased:to:be'
