require File.expand_path('../boot', __FILE__)
require_relative 'initializer_instrumentation'

RailsApplicationInstrumentation.instrument("rails/all require") do
  require 'rails/all'
end
require 'elasticsearch/rails/instrumentation'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
RailsApplicationInstrumentation.instrument("Bundler.require") do
  Bundler.require(*Rails.groups)
end

module Gemcutter
  class Application < Rails::Application
    include RailsApplicationInstrumentation

    config.rubygems = Application.config_for :rubygems

    config.time_zone = "UTC"
    config.encoding  = "utf-8"
    config.i18n.available_locales = [:en, :nl, 'zh-CN', 'zh-TW', 'pt-BR', :fr, :es]
    config.i18n.fallbacks = true

    config.middleware.use "Redirector" unless Rails.env.development?

    config.active_record.include_root_in_json = false
    config.active_record.raise_in_transactional_callbacks = true

    config.after_initialize do
      RubygemFs.s3! ENV['S3_PROXY'] if ENV['S3_PROXY']
    end

    config.plugins = [:dynamic_form]

    config.autoload_paths << Rails.root.join('lib')
  end

  def self.config
    Rails.application.config.rubygems
  end

  PROTOCOL = config['protocol']
  HOST = config['host']
end
