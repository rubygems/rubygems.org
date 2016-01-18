require File.expand_path('../boot', __FILE__)
require_relative 'initializer_instrumentation'

RailsApplicationInstrumentation.instrument("rails/all require") do
  require 'rails/all'
end
require 'jquery-rails'
require 'uglifier'
# https://github.com/mime-types/ruby-mime-types/issues/94
# This can be removed once all gems depend on > 3.0
require 'mime/types/columnar'

# Engines
require 'rails-i18n'
require 'clearance'
require 'clearance-deprecated_password_strategies'
require 'doorkeeper'
require 'autoprefixer-rails'
require 'paul_revere'
require 'will_paginate'
require 'statsd-instrument'
require 'high_voltage'
require 'gravtastic'

## TODO: Elasctic search, should probably be lazy loaded
require 'elasticsearch/rails/instrumentation'
require 'elasticsearch/model'
require 'elasticsearch/rails'
require 'elasticsearch/dsl'

## TODO: new relic probably should be only required on production
require 'newrelic-redis'
require 'newrelic_rpm'

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
    require "http_accept_language"
    config.middleware.use HttpAcceptLanguage::Middleware

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
