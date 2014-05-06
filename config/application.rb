# TODO: Remove this before merging to master, after rubygems changes have
# shipped.
$LOAD_PATH.unshift(File.expand_path('../../../rubygems/lib', __FILE__))

begin
  require 'openssl'
  require 'rubygems/tuf'
rescue LoadError
  $stderr.puts <<-EOS
Your version of rubygems is too old, it does not include rubygems/tuf which
is required for secure operation.
  EOS
  exit 1
end

require File.expand_path('../boot', __FILE__)

require 'rails'
require 'action_controller/railtie'

unless Rails.env.maintenance?
  require 'rails/test_unit/railtie'
  require 'action_mailer/railtie'
  require 'active_record/railtie'
end

Bundler.require(:default, Rails.env) if defined?(Bundler)

$rubygems_config = YAML.load_file("config/rubygems.yml")[Rails.env].symbolize_keys
HOST             = $rubygems_config[:host]

RUBYGEMS_VERSION = "2.2.2"

module Gemcutter
  class Application < Rails::Application
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
  end
end
