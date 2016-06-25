require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'elasticsearch/rails/instrumentation'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gemcutter
  class Application < Rails::Application
    config.rubygems = Application.config_for :rubygems

    config.time_zone = "UTC"
    config.encoding  = "utf-8"
    config.i18n.available_locales = [:en, :nl, 'zh-CN', 'zh-TW', 'pt-BR', :fr, :es, :de]
    config.i18n.fallbacks = true

    config.active_record.include_root_in_json = false

    config.after_initialize do
      RubygemFs.s3! ENV['S3_PROXY'] if ENV['S3_PROXY']
    end

    config.plugins = [:dynamic_form]

    config.autoload_paths << Rails.root.join('lib')

    # halt callback chains when a callback returns false.
    ActiveSupport.halt_callback_chains_on_return_false = true
  end

  def self.config
    Rails.application.config.rubygems
  end

  PROTOCOL = config['protocol']
  HOST = config['host']
end
