require File.expand_path('../boot', __FILE__)

require 'rails'
require 'action_controller/railtie'

unless Rails.env.maintenance?
  require 'rails/test_unit/railtie'
  require 'action_mailer/railtie'
  require 'active_record/railtie'
  require 'sprockets/railtie'
end

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

$rubygems_config = YAML.load_file("config/rubygems.yml")[Rails.env].symbolize_keys
HOST             = $rubygems_config[:host]

module Gemcutter
  class Application < Rails::Application
    config.assets.enabled = true

    config.time_zone = "UTC"
    config.encoding  = "utf-8"

    config.middleware.use "Hostess"
    config.middleware.insert_after "Hostess", "Redirector" if $rubygems_config[:redirector] && ENV["LOCAL"].nil?

    unless Rails.env.maintenance?
      config.action_mailer.default_url_options  = { :host => HOST }
      config.action_mailer.delivery_method      = $rubygems_config[:delivery_method]
      config.active_record.include_root_in_json = false
    end

    config.after_initialize do
      Hostess.local = $rubygems_config[:local_storage]
    end

    config.plugins = [:dynamic_form]
    config.plugins << :heroku_asset_cacher if $rubygems_config[:asset_cacher]

    config.autoload_paths << "./app/jobs"
    # Use strong parameters instead
    config.active_record.whitelist_attributes = false
  end
end
