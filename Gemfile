source "https://rubygems.org"

gem "rails", "~> 7.1.0"
gem "rails-i18n", "~> 7.0"

gem "aws-sdk-s3", "~> 1.142"
gem "aws-sdk-sqs", "~> 1.69"
gem "bootsnap", "~> 1.17"
gem "clearance", "~> 2.6"
gem "dalli", "~> 3.2"
gem "ddtrace", "~> 1.19", require: "ddtrace/auto_instrument"
gem "dogstatsd-ruby", "~> 5.5"
gem "google-protobuf", "~> 3.25"
gem "faraday", "~> 2.9"
gem "faraday-retry", "~> 2.2"
gem "good_job", "~> 3.23"
gem "gravtastic", "~> 3.2"
gem "high_voltage", "~> 3.1"
gem "honeybadger", "~> 5.4"
gem "http_accept_language", "~> 2.1"
gem "jquery-rails", "~> 4.5"
gem "kaminari", "~> 1.2"
gem "launchdarkly-server-sdk", "~> 8.1"
gem "mail", "~> 2.8"
gem "octokit", "~> 8.0"
gem "omniauth-github", "~> 2.0"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "openid_connect", "~> 2.3"
gem "pg", "~> 1.4"
gem "puma", "~> 6.4"
gem "rack", "~> 3.0"
gem "rack-utf8_sanitizer", "~> 1.8"
gem "rbtrace", "~> 0.5.1"
gem "rdoc", "~> 6.6"
gem "roadie-rails", "~> 3.0"
gem "ruby-magic", "~> 0.6"
gem "shoryuken", "~> 6.1", require: false
gem "statsd-instrument", "~> 3.5"
gem "validates_formatting_of", "~> 0.9"
gem "opensearch-ruby", "~> 3.1"
gem "searchkick", "~> 5.3"
gem "faraday_middleware-aws-sigv4", "~> 1.0"
gem "xml-simple", "~> 1.1"
gem "compact_index", "~> 0.15.0"
gem "sprockets-rails", "~> 3.4"
gem "rack-attack", "~> 6.6"
gem "rqrcode", "~> 2.1"
gem "rotp", "~> 6.2"
gem "unpwn", "~> 1.0"
gem "webauthn", "~> 3.1"
gem "browser", "~> 5.3", ">= 5.3.1"
gem "bcrypt", "~> 3.1"
gem "maintenance_tasks", "~> 2.4"
gem "strong_migrations", "~> 1.7"
gem "phlex-rails", "~> 1.1"

# Admin dashboard
gem "avo", "~> 2.47"
gem "view_component", "~> 3.10"
gem "pundit", "~> 2.3"
gem "chartkick", "~> 5.0"
gem "groupdate", "~> 6.2"

# Logging
gem "amazing_print", "~> 1.4"
gem "rails_semantic_logger", "~> 4.14"
gem "pp", "0.5.0"

# Former default gems
gem "csv", "~> 3.2" # zeitwerk-2.6.12
gem "observer", "~> 0.1.2" # launchdarkly-server-sdk-8.0.0

group :assets, :development do
  gem "tailwindcss-rails", "~> 2.3"
end

group :assets do
  gem "dartsass-sprockets", "~> 3.1"
  gem "terser", "~> 1.2"
  gem "autoprefixer-rails", "~> 10.4"
end

group :development, :test do
  gem "pry-byebug", "~> 3.10"
  gem "toxiproxy", "~> 2.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "dotenv-rails", "~> 2.8"

  gem "brakeman", "~> 6.1", require: false

  # bundle show | rg rubocop | cut -d' ' -f4 | xargs bundle update
  gem "rubocop", "~> 1.48", require: false
  gem "rubocop-rails", "~> 2.18", require: false
  gem "rubocop-performance", "~> 1.16", require: false
  gem "rubocop-minitest", "~> 0.29", require: false
  gem "rubocop-capybara", "~> 2.17", require: false
  gem "rubocop-factory_bot", "~> 2.25", require: false
end

group :development do
  gem "rails-erd", "~> 1.7"
  gem "listen", "~> 3.8"
  gem "letter_opener", "~> 1.8"
  gem "letter_opener_web", "~> 2.0"
  gem "derailed_benchmarks", "~> 2.1"
  gem "memory_profiler", "~> 1.0"
end

group :test do
  gem "minitest", "~> 5.21", require: false
  gem "capybara", "~> 3.38"
  gem "launchy", "~> 2.5"
  gem "rack-test", "~> 2.1", require: "rack/test"
  gem "rails-controller-testing", "~> 1.0"
  gem "mocha", "~> 2.0", require: false
  gem "shoulda-context", "~> 2.0"
  gem "shoulda-matchers", "~> 6.1"
  gem "selenium-webdriver", "~> 4.17"
  gem "webmock", "~> 3.18"
  gem "simplecov", "~> 0.22", require: false
  gem "simplecov-cobertura", "~> 2.1", require: false
  gem "aggregate_assertions", "~> 0.2.0"
  gem "minitest-gcstats", "~> 1.3"
  gem "minitest-reporters", "~> 1.6"
end
