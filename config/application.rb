require File.expand_path('../boot', __FILE__)

require 'rails'
require 'action_controller/railtie'

if 'maintenance' != ENV["RAILS_ENV"]
  require 'rails/all'
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gemcutter
  class Application < Rails::Application
    def config_for(name, env = Rails.env)
      YAML.load_file(Rails.root.join("config/#{name}.yml"))[env]
    end
    config.rubygems = Application.config_for :rubygems

    config.time_zone = "UTC"
    config.encoding  = "utf-8"

    config.middleware.use "Hostess"
    if config.rubygems['redirector'] && ENV["LOCAL"].nil?
      config.middleware.insert_after "Hostess", "Redirector"
    end

    unless Rails.env.maintenance?
      config.active_record.include_root_in_json = false
    end

    config.after_initialize do
      Hostess.local = config.rubygems['local_storage']
    end

    config.plugins = [:dynamic_form]
    config.plugins << :heroku_asset_cacher if config.rubygems['asset_cacher']

    config.autoload_paths << "./app/jobs"
  end

  def self.config
    Rails.application.config.rubygems
  end

  HOST = config['host']
end
