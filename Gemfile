source "https://rubygems.org"

gem "rails", "~> 7.0.0"
gem "rails-i18n"

gem "aws-sdk-s3"
gem "aws-sdk-sqs"
gem "bootsnap"
gem "clearance"
gem "dalli"
gem "ddtrace", require: "ddtrace/auto_instrument"
gem "dogstatsd-ruby"
gem "google-protobuf"
gem "delayed_job"
gem "delayed_job_active_record"
gem "faraday", "~> 1.10"
gem "good_job"
gem "gravtastic"
gem "high_voltage"
gem "honeybadger"
gem "http_accept_language"
gem "jquery-rails"
gem "kaminari"
gem "launchdarkly-server-sdk"
gem "mail"
gem "octokit"
gem "omniauth-github"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "pg"
gem "puma"
gem "rack"
gem "rack-utf8_sanitizer"
gem "rbtrace", "~> 0.4.8"
gem "rdoc"
gem "roadie-rails"
gem "ruby-magic"
gem "shoryuken", "~> 4.0", require: false
gem "statsd-instrument", "~> 3.5"
gem "validates_formatting_of"
gem "opensearch-dsl", "~> 0.2.0"
gem "opensearch-ruby", "~> 1.0.0"
gem "searchkick"
gem "faraday_middleware-aws-sigv4", "~> 0.3"
gem "xml-simple"
gem "compact_index", "~> 0.14.0"
gem "sprockets-rails"
gem "rack-attack"
gem "rqrcode"
gem "rotp"
gem "unpwn"
gem "webauthn"

# Admin dashboard
gem "avo"
gem "pundit"
gem "chartkick"
gem "groupdate"

# Logging
gem "amazing_print"
gem "rails_semantic_logger"

group :assets do
  gem "sassc-rails"
  gem "terser"
  gem "autoprefixer-rails"
end

group :development, :test do
  gem "m", "~> 1.5", require: false
  gem "pry-byebug"
  gem "toxiproxy", "~> 2.0.0"
  gem "factory_bot_rails"

  gem "brakeman", require: false
  gem "rubocop", "~> 1.48", require: false
  gem "rubocop-rails", "~> 2.18", require: false
  gem "rubocop-performance", "~> 1.16", require: false
  gem "rubocop-minitest", "~> 0.29", require: false
  gem "rubocop-capybara", "~> 2.17", require: false
end

group :development do
  gem "rails-erd"
  gem "listen"
  gem "letter_opener"
  gem "letter_opener_web"
end

group :test do
  gem "minitest", require: false
  gem "capybara", "~> 3.35"
  gem "launchy"
  gem "rack-test", require: "rack/test"
  gem "mocha", require: false
  gem "shoulda"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "webmock"
  gem "simplecov", require: false
  gem "simplecov-cobertura", require: false
end
