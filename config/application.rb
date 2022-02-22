require_relative "boot"

require "rails"
# Pick the frameworks you want:
# require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require "elasticsearch/rails/instrumentation"
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gemcutter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Using true enables origin-checking CSRF mitigation. Our API can"t use this check.
    config.action_controller.forgery_protection_origin_check = false

    config.rubygems = Application.config_for :rubygems

    config.time_zone = "UTC"
    config.encoding  = "utf-8"
    config.i18n.available_locales = [:en, :nl, "zh-CN", "zh-TW", "pt-BR", :fr, :es, :de, :ja]
    config.i18n.fallbacks = [:en]

    config.middleware.insert 0, Rack::UTF8Sanitizer
    config.middleware.use Rack::Attack
    config.middleware.use Rack::Deflater

    config.active_record.include_root_in_json = false

    config.after_initialize do
      RubygemFs.s3! ENV["S3_PROXY"] if ENV["S3_PROXY"]
    end

    config.plugins = [:dynamic_form]

    config.eager_load_paths << Rails.root.join("lib")
    config.toxic_domains_filepath = Rails.root.join("vendor", "toxic_domains_whole.txt")
  end

  def self.config
    Rails.application.config.rubygems
  end

  DEFAULT_PAGE = 1
  DEFAULT_PAGINATION = 20
  EMAIL_TOKEN_EXPRIES_AFTER = 3.hours
  HOST = config["host"]
  NEWS_DAYS_LIMIT = 7.days
  NEWS_MAX_PAGES = 10
  NEWS_PER_PAGE = 10
  MAX_PAGES = 1000
  MFA_KEY_EXPIRY = 30.minutes
  OWNERSHIP_TOKEN_EXPIRES_AFTER = 48.hours
  POPULAR_DAYS_LIMIT = 70.days
  PROTOCOL = config["protocol"]
  REMEMBER_FOR = 2.weeks
  SEARCH_MAX_PAGES = 100 # Limit max page as ES result window is upper bounded by 10_000 records
  STATS_MAX_PAGES = 10
  STATS_PER_PAGE = 10
  MAX_FIELD_LENGTH = 255
  PASSWORD_VERIFICATION_EXPIRY = 10.minutes
  MAX_TEXT_FIELD_LENGTH = 64_000
  OWNERSHIP_CALLS_PER_PAGE = 10
end
