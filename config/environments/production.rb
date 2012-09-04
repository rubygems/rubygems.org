Gemcutter::Application.configure do
  config.cache_classes = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.active_support.deprecation = :notify
  config.serve_static_assets = $rubygems_config[:asset_cacher]
  config.i18n.fallbacks = true
  config.log_level = :error

  config.action_dispatch.session = {
    :domain => ".rubygems.org",
    :secure => true
  }

  # if on heroku:
  # config.action_mailer.smtp_settings = {
  #   :address        => "smtp.sendgrid.net",
  #   :port           => "25",
  #   :authentication => :plain,
  #   :user_name      => ENV['SENDGRID_USERNAME'],
  #   :password       => ENV['SENDGRID_PASSWORD'],
  #   :domain         => ENV['SENDGRID_DOMAIN']
  # }
end

require Rails.root.join("config", "secret") if Rails.root.join("config", "secret.rb").file?
