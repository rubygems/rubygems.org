require File.expand_path('../boot', __FILE__)

require 'rails'
require 'action_controller/railtie'

unless Rails.env.maintenance?
  require 'rails/test_unit/railtie'
  require 'action_mailer/railtie'
  require 'active_record/railtie'
end

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

$rubygems_config = YAML.load_file("config/rubygems.yml")[Rails.env].symbolize_keys
HOST             = $rubygems_config[:host]

# DO NOT EDIT THIS LINE DIRECTLY
# Instead, run: bundle exec rake gemcutter:rubygems:update VERSION=[version number] RAILS_ENV=[staging|production] S3_KEY=[key] S3_SECRET=[secret]
RUBYGEMS_VERSION = "1.8.10"

module RubygemsOrg
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.middleware.use "Hostess"
    config.middleware.insert_after "Hostess", "Redirector" if $rubygems_config[:redirector]

    unless Rails.env.maintenance?
      config.action_mailer.default_url_options  = { :host => HOST }
      config.action_mailer.delivery_method      = $rubygems_config[:delivery_method]
      config.active_record.include_root_in_json = false
    end

    config.after_initialize do
      Hostess.local = $rubygems_config[:local_storage]
    end

    config.plugins = [:dynamic_form]
  end
end
