source "https://rubygems.org"

gem "rails", "~> 7.0.0"
gem "rails-i18n", "~> 7.0"

gem "aws-sdk-s3", "~> 1.119"
gem "aws-sdk-sqs", "~> 1.53"
gem "bootsnap", "~> 1.16"
gem "clearance", "~> 2.6"
gem "dalli", "~> 3.2"
gem "ddtrace", "~> 1.10", require: "ddtrace/auto_instrument"
gem "dogstatsd-ruby", "~> 5.5"
gem "google-protobuf", "~> 3.22"
gem "faraday", "~> 1.10"
gem "good_job", "~> 3.17"
gem "gravtastic", "~> 3.2"
gem "high_voltage", "~> 3.1"
gem "honeybadger", "~> 5.2"
gem "http_accept_language", "~> 2.1"
gem "jquery-rails", "~> 4.5"
gem "kaminari", "~> 1.2"
gem "launchdarkly-server-sdk", "~> 7.0"
gem "mail", "~> 2.8"
gem "octokit", "~> 6.1"
gem "omniauth-github", "~> 2.0"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "openid_connect", "~> 1.4"
gem "pg", "~> 1.4"
gem "puma", "~> 6.1"
gem "rack", "~> 2.2"
gem "rack-utf8_sanitizer", "~> 1.8"
gem "rbtrace", "~> 0.4.8"
gem "rdoc", "~> 6.5"
gem "roadie-rails", "~> 3.0"
gem "ruby-magic", "~> 0.6"
gem "shoryuken", "~> 4.0", require: false
gem "statsd-instrument", "~> 3.5"
gem "validates_formatting_of", "~> 0.9"
gem "opensearch-dsl", "~> 0.2.0"
gem "opensearch-ruby", "~> 1.0"
gem "searchkick", "~> 5.2"
gem "faraday_middleware-aws-sigv4", "~> 0.6"
gem "xml-simple", "~> 1.1"
gem "compact_index", "~> 0.14.0"
gem "sprockets-rails", "~> 3.4"
gem "rack-attack", "~> 6.6"
gem "rqrcode", "~> 2.1"
gem "rotp", "~> 6.2"
gem "unpwn", "~> 1.0"
gem "webauthn", "~> 3.0"
gem "browser", "~> 5.3", ">= 5.3.1"
gem "bcrypt", "~> 3.1", ">= 3.1.18"
gem "maintenance_tasks", "~> 2.1"
gem "strong_migrations", "~> 1.6"

# Admin dashboard
gem "avo", "~> 2.28", "< 2.36" # 2.36+ requires to fix test failures
gem "view_component", "~> 2.0"
gem "pundit", "~> 2.3"
gem "chartkick", "~> 5.0"
gem "groupdate", "~> 6.2"

# Logging
gem "amazing_print", "~> 1.4"
gem "rails_semantic_logger", "~> 4.11"

group :assets do
  gem "dartsass-sprockets", "~> 3.0"
  gem "terser", "~> 1.1"
  gem "autoprefixer-rails", "~> 10.4"
end

group :development, :test do
  gem "m", "~> 1.6", require: false
  gem "pry-byebug", "~> 3.10"
  gem "toxiproxy", "~> 2.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "dotenv-rails", "~> 2.8"

  gem "brakeman", "~> 6.0", require: false
  gem "rubocop", "~> 1.48", require: false
  gem "rubocop-rails", "~> 2.18", require: false
  gem "rubocop-performance", "~> 1.16", require: false
  gem "rubocop-minitest", "~> 0.29", require: false
  gem "rubocop-capybara", "~> 2.17", require: false
end

group :development do
  gem "rails-erd", "~> 1.7"
  gem "listen", "~> 3.8"
  gem "letter_opener", "~> 1.8"
  gem "letter_opener_web", "~> 2.0"
end

group :test do
  gem "minitest", "~> 5.18", require: false
  gem "capybara", "~> 3.38"
  gem "launchy", "~> 2.5"
  gem "rack-test", "~> 2.1", require: "rack/test"
  gem "rails-controller-testing", "~> 1.0"
  gem "mocha", "~> 2.0", require: false
  gem "shoulda", "~> 4.0"
  gem "selenium-webdriver", "~> 4.8"
  gem "webmock", "~> 3.18"
  gem "simplecov", "~> 0.22", require: false
  gem "simplecov-cobertura", "~> 2.1", require: false
  gem "aggregate_assertions", "~> 0.2.0"
end
