require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

module Gemcutter
  class Application < Rails::Application
    config.time_zone = 'UTC'
    config.action_mailer.delivery_method = :sendmail
    config.load_paths << Rails.root.join('app', 'middleware')
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
  end
end
