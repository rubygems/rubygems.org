Gemcutter::Application.configure do
  # for testing recovery mode on your local machine, LOCAL=1 rails s -e recovery
  if ENV["LOCAL"]
    config.cache_classes = false
    config.whiny_nils = true

    config.consider_all_requests_local = true
    config.action_controller.perform_caching             = false
    config.active_support.deprecation = :log
    config.action_mailer.raise_delivery_errors = false
  else
    config.cache_classes = true
    config.consider_all_requests_local = false
    config.action_controller.perform_caching = true
    config.action_dispatch.x_sendfile_header = "X-Sendfile"
    config.active_support.deprecation = :notify
    config.serve_static_assets = $rubygems_config[:asset_cacher]
    config.i18n.fallbacks = true

    config.action_dispatch.session = {
      :domain => ".rubygems.org",
      :secure => true
    }
  end

  config.middleware.insert_after "Hostess", "RecoveryMode"
end

require Rails.root.join("config", "secret") if Rails.root.join("config", "secret.rb").file?
