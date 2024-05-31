require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
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

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gemcutter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks cops shoryuken])

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

    require_relative '../lib/gemcutter/middleware/admin_auth'
    config.middleware.use ::Gemcutter::Middleware::AdminAuth

    config.active_record.include_root_in_json = false

    config.after_initialize do
      RubygemFs.s3! ENV["S3_PROXY"] if ENV["S3_PROXY"]
    end

    config.toxic_domains_filepath = Rails.root.join("vendor", "toxic_domains_whole.txt")

    config.active_job.queue_adapter = :good_job

    config.add_autoload_paths_to_load_path = false
    config.autoload_paths << "#{root}/app/views"
    config.autoload_paths << "#{root}/app/views/layouts"
    config.autoload_paths << "#{root}/app/views/components"

    config.active_support.cache_format_version = 7.1

    config.action_dispatch.rescue_responses["Rack::Multipart::EmptyContentError"] = :bad_request
  end

  def self.config
    Rails.application.config.rubygems
  end

  DEFAULT_PAGE = 1
  DEFAULT_PAGINATION = 20
  EMAIL_TOKEN_EXPIRES_AFTER = 3.hours
  HOST = config["host"].freeze
  HOST_DISPLAY = Rails.env.production? || Rails.env.development? || Rails.env.test? ? "RubyGems.org" : "RubyGems.org #{Rails.env}"
  NEWS_DAYS_LIMIT = 7.days
  NEWS_MAX_PAGES = 10
  NEWS_PER_PAGE = 10
  MAX_PAGES = 1000
  MFA_KEY_EXPIRY = 30.minutes
  OWNERSHIP_TOKEN_EXPIRES_AFTER = 48.hours
  POPULAR_DAYS_LIMIT = 70.days
  PROTOCOL = config["protocol"]
  REMEMBER_FOR = 2.weeks
  SEARCH_INDEX_NAME = "rubygems-#{Rails.env}".freeze
  SEARCH_NUM_REPLICAS = ENV.fetch("SEARCH_NUM_REPLICAS", 1).to_i
  SEARCH_MAX_PAGES = 100 # Limit max page as ES result window is upper bounded by 10_000 records
  STATS_MAX_PAGES = 10
  STATS_PER_PAGE = 10
  MAX_FIELD_LENGTH = 255
  PASSWORD_VERIFICATION_EXPIRY = 10.minutes
  MAX_TEXT_FIELD_LENGTH = 64_000
  OWNERSHIP_CALLS_PER_PAGE = 10
  GEM_REQUEST_LIMIT = 400
  VERSIONS_PER_PAGE = 100
  SEPARATE_ADMIN_HOST = config["separate_admin_host"]
  ENABLE_DEVELOPMENT_ADMIN_LOG_IN = Rails.env.local?
  MAIL_SENDER = "RubyGems.org <no-reply@mailer.rubygems.org>".freeze
end
