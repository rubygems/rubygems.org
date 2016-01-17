require File.expand_path('../boot', __FILE__)
require_relative 'initializer_instrumentation'

RailsApplicationInstrumentation.instrument("rails/all require") do
  require 'rails/all'
end
require 'jquery-rails'

require 'elasticsearch/rails/instrumentation'

# Engines
require 'rails-i18n'
require 'clearance'
require 'clearance-deprecated_password_strategies'
require 'doorkeeper'
require 'autoprefixer-rails'
require 'paul_revere'
require 'will_paginate'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
RailsApplicationInstrumentation.instrument("Bundler.require") do
  Bundler.require(*Rails.groups)
end

module Gemcutter
  class Application < Rails::Application
    include RailsApplicationInstrumentation

    initializer :regenerate_require_cache, before: :load_environment_config do
      Bootscale.regenerate
    end

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

  JOB_PRIORITIES = { push: 1, download: 2, web_hook: 3 }
end
