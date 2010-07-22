require File.expand_path('../boot', __FILE__)

require 'rails'
require 'action_controller/railtie'

unless Rails.env.maintenance?
  require 'rails/test_unit/railtie'
  require 'action_mailer/railtie'
  require 'active_record/railtie'
end

Bundler.require(:default, Rails.env) if defined?(Bundler)

module Gemcutter
  class Application < Rails::Application
    config.time_zone = 'UTC'
    config.encoding  = "utf-8"
    config.middleware.use "Hostess"

    unless Rails.env.maintenance?
      config.action_mailer.delivery_method = :sendmail
      config.active_record.include_root_in_json = false
    end
  end
end
