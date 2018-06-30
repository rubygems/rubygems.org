source 'https://rubygems.org'

# https://github.com/mime-types/ruby-mime-types/issues/94
# This can be removed once all gems depend on > 3.0
gem 'mime-types', '~> 2.99', require: 'mime/types/columnar'

gem 'rails', '~> 5.1.0'
gem 'rails-i18n'

gem 'autoprefixer-rails'
gem 'aws-sdk', '~> 2.2'
gem 'clearance'
gem 'clearance-deprecated_password_strategies'
gem 'daemons'
gem 'dalli'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'dynamic_form'
gem 'gravtastic'
gem 'high_voltage'
gem 'highline'
gem 'honeybadger'
gem 'http_accept_language'
gem 'jquery-rails'
gem 'mail', '2.6.6'
gem 'newrelic_rpm'
gem 'paul_revere', '~> 3.0.0'
gem 'pg'
gem 'rack'
gem 'rack-utf8_sanitizer'
gem 'rbtrace', '~> 0.4.8'
gem 'rdoc'
gem 'rest-client', require: 'rest_client'
gem 'sass', require: false
gem 'shoryuken', '~> 2.1.0', require: false
gem 'statsd-instrument', '~> 2.1.0'
gem 'uglifier', '>= 1.0.3'
gem 'unicorn'
gem 'validates_formatting_of'
gem 'will_paginate'
gem 'elasticsearch-model', '~> 5.0.0'
gem 'elasticsearch-rails', '~> 5.0.0'
gem 'elasticsearch-dsl', '~> 0.1.2'
gem 'xml-simple'
gem 'compact_index', '~> 0.11.0'
gem 'sprockets-rails'
gem 'rack-attack'

# Logging
gem 'lograge'
gem 'logstash-event'

group :development, :test do
  gem 'rubocop', require: false
  gem 'toxiproxy', '~> 1.0.0'
end

group :development do
  gem 'bootsnap', require: false
  gem 'rails-erd'
end

group :test do
  gem 'minitest', require: false
  gem 'capybara', '~> 2.18'
  gem 'factory_bot_rails'
  gem 'launchy'
  gem 'rack-test', require: 'rack/test'
  gem 'mocha', require: false
  gem 'bourne', require: false
  gem 'shoulda', require: false
end

group :development, :deploy do
  gem 'capistrano', '~> 3.0', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
end
