source 'https://rubygems.org'

gem 'rails', '~> 4.2.5.rc1'
gem 'rails-i18n'

gem 'autoprefixer-rails'
gem 'aws-sdk-core'
gem 'builder'
gem 'clearance'
gem 'clearance-deprecated_password_strategies'
gem 'coffee-rails', '~> 4.1'
gem 'daemons'
gem 'dalli'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'doorkeeper'
gem 'dynamic_form'
gem 'gchartrb', require: 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'highline'
gem 'honeybadger', '~> 2.1.0'
gem 'http_accept_language'
gem 'jquery-rails'
gem 'mail'
gem 'multi_json'
gem 'newrelic-redis'
gem 'newrelic_rpm'
gem 'paul_revere', '~> 2.0'
gem 'pg'
gem 'psych', '~> 2.0.12'
gem 'rack'
gem 'rdoc'
gem 'redis'
gem 'rest-client', require: 'rest_client'
gem 'sass-rails', '~> 5.0.0'
gem 'statsd-instrument', '~> 2.0.6'
gem 'uglifier', '>= 1.0.3'
gem 'unicorn'
gem 'validates_formatting_of'
gem 'will_paginate'
gem 'elasticsearch-model', '~> 0.1.7'
gem 'elasticsearch-rails', '~> 0.1.7'
gem 'xml-simple'
gem 'yajl-ruby', require: 'yajl'

group :development, :test do
  gem 'rubocop', '~> 0.34.0'
  gem 'toxiproxy', '~> 0.1.3'
end

group :development do
  gem 'quiet_assets'
  gem 'rails-erd'
end

group :test do
  gem 'minitest', require: false
  gem 'capybara'
  gem 'factory_girl_rails'
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

platforms :jruby do
  gem 'jruby-openssl'
end
