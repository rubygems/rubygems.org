source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 7.1.0", ">= 7.1.3.2"
gem "rails-i18n", "~> 7.0"

gem "aws-sdk-s3", "~> 1.156"
gem "aws-sdk-sqs", "~> 1.80"
gem "bootsnap", "~> 1.18"
gem "clearance", "~> 2.7"
gem "dalli", "~> 3.2"
gem "datadog", "~> 2.1", require: "datadog/auto_instrument"
gem "dogstatsd-ruby", "~> 5.5"
gem "google-protobuf", "~> 4.27"
gem "faraday", "~> 2.10"
gem "faraday-retry", "~> 2.2"
gem "good_job", "~> 3.29"
gem "gravtastic", "~> 3.2"
gem "honeybadger", "~> 5.5.1" # see https://github.com/rubygems/rubygems.org/pull/4598
gem "http_accept_language", "~> 2.1"
gem "kaminari", "~> 1.2"
gem "launchdarkly-server-sdk", "~> 8.6"
gem "mail", "~> 2.8"
gem "octokit", "~> 9.1"
gem "omniauth-github", "~> 2.0"
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "openid_connect", "~> 2.3"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "rack", "~> 3.1"
gem "rackup", "~> 2.1"
gem "rack-utf8_sanitizer", "~> 1.8"
gem "rbtrace", "~> 0.5.1"
gem "rdoc", "~> 6.7"
gem "roadie-rails", "~> 3.2"
gem "ruby-magic", "~> 0.6"
gem "shoryuken", "~> 6.2", require: false
gem "statsd-instrument", "~> 3.8"
gem "validates_formatting_of", "~> 0.9"
gem "opensearch-ruby", "~> 3.3"
gem "searchkick", "~> 5.3"
gem "faraday_middleware-aws-sigv4", "~> 1.0"
gem "xml-simple", "~> 1.1"
gem "compact_index", "~> 0.15.0"
gem "rack-attack", "~> 6.6"
gem "rqrcode", "~> 2.1"
gem "rotp", "~> 6.2"
gem "unpwn", "~> 1.0"
gem "webauthn", "~> 3.1"
gem "browser", "~> 6.0"
gem "bcrypt", "~> 3.1"
gem "maintenance_tasks", "~> 2.7"
gem "strong_migrations", "~> 2.0"
gem "phlex-rails", "~> 1.2"
gem "discard", "~> 1.3"
gem "user_agent_parser", "~> 2.18"
gem "pghero", "~> 3.5"
gem "timescaledb", "~> 0.2"

# Admin dashboard
gem "avo", "~> 2.51"
gem "view_component", "~> 3.12"
gem "pundit", "~> 2.3"
gem "chartkick", "~> 5.0"
gem "groupdate", "~> 6.2"

# Logging
gem "amazing_print", "~> 1.6"
gem "rails_semantic_logger", "~> 4.17"
gem "pp", "0.5.0"

# Former default gems
gem "csv", "~> 3.3" # zeitwerk-2.6.12
gem "observer", "~> 0.1.2" # launchdarkly-server-sdk-8.0.0

# Assets
gem "sprockets-rails", "~> 3.5"
gem "importmap-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3" # this adds stimulus-loading.js so it must be available at runtime
gem "better_html", "~> 2.1"

group :assets, :development do
  gem "tailwindcss-rails", "~> 2.6"
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
  gem "dotenv-rails", "~> 3.1"
  gem "lookbook", "~> 2.3"

  gem "brakeman", "~> 6.1", require: false

  # used to find n+1 queries
  gem "prosopite", "~> 1.4"
  gem "pg_query", "~> 5.1"

  # bundle show | rg rubocop | cut -d' ' -f4 | xargs bundle update
  gem "rubocop", "~> 1.64", require: false
  gem "rubocop-rails", "~> 2.25", require: false
  gem "rubocop-performance", "~> 1.21", require: false
  gem "rubocop-minitest", "~> 0.35", require: false
  gem "rubocop-capybara", "~> 2.21", require: false
  gem "rubocop-factory_bot", "~> 2.26", require: false
end

group :development do
  gem "rails-erd", "~> 1.7"
  gem "listen", "~> 3.9"
  gem "letter_opener", "~> 1.10"
  gem "letter_opener_web", "~> 3.0"
  gem "derailed_benchmarks", "~> 2.1"
  gem "memory_profiler", "~> 1.0"
end

group :test do
  gem "datadog-ci", "~> 1.1"
  gem "minitest", "~> 5.24", require: false
  gem "minitest-retry", "~> 0.2.2"
  gem "capybara", "~> 3.40"
  gem "launchy", "~> 3.0"
  gem "rack-test", "~> 2.1", require: "rack/test"
  gem "rails-controller-testing", "~> 1.0"
  gem "mocha", "~> 2.4", require: false
  gem "shoulda-context", "~> 3.0.0.rc1"
  gem "shoulda-matchers", "~> 6.2"
  gem "selenium-webdriver", "~> 4.22"
  gem "webmock", "~> 3.23"
  gem "simplecov", "~> 0.22", require: false
  gem "simplecov-cobertura", "~> 2.1", require: false
  gem "aggregate_assertions", "~> 0.2.0"
  gem "minitest-gcstats", "~> 1.3"
  gem "minitest-reporters", "~> 1.7"
end
