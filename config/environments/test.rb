HOST = 'www.example.com'

Gemcutter::Application.configure do
  config.cache_classes = true
  config.whiny_nils = true

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false

  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = {:host => HOST}
end

ENV['S3_KEY']    = 'this:is:an:ex:parrot'
ENV['S3_SECRET'] = 'it:has:ceased:to:be'
