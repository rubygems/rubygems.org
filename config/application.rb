require_relative 'boot'


require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'rails/test_unit/railtie'
require 'sprockets/railtie'
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

    config.middleware.insert 0, Rack::UTF8Sanitizer
    config.middleware.use Rack::Attack
    config.middleware.use Rack::Deflater

    config.active_record.include_root_in_json = false

    config.after_initialize do
      RubygemFs.s3! ENV['S3_PROXY'] if ENV['S3_PROXY']
    end

    config.plugins = [:dynamic_form]

    config.eager_load_paths << Rails.root.join('lib')
  end

  def self.config
    Rails.application.config.rubygems
  end

  PROTOCOL = config['protocol']
  HOST = config['host']
  DEFAULT_PAGINATION = 20
  REMEMBER_FOR = 2.weeks
  MFA_KEY_EXPIRY = 30.minutes
  NEWS_MAX_PAGES = 10
  NEWS_PER_PAGE = 10
  NEWS_DAYS_LIMIT = 7.days
  POPULAR_DAYS_LIMIT = 70.days
  # Limit max page as ES result window is upper bounded by 10_000 records
  SEARCH_MAX_PAGES = 100
  EMAIL_TOKEN_EXPRIES_AFTER = 3.hours
end
