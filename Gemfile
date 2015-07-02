source 'https://rubygems.org'

gem 'rails', '~> 4.2.2'

gem 'psych', '~> 2.0.12'
gem 'builder'
gem 'dynamic_form'
gem 'aws-sdk-core'
gem 'gchartrb', require: 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'highline'
gem 'honeybadger', '~> 2.1.0'
gem 'jquery-rails'
gem 'mail'
gem 'dalli'
gem 'multi_json'
gem 'paul_revere', '~> 1.4'
gem 'pg'
gem 'rack'
gem 'rdoc', '~> 3.12.2'
gem 'redis'
gem 'rest-client', require: 'rest_client'
gem 'statsd-instrument', '~> 2.0.6'
gem 'unicorn'
gem 'validates_formatting_of'
gem 'will_paginate'
gem 'xml-simple'
gem 'yajl-ruby', require: 'yajl'
gem 'autoprefixer-rails'
gem 'clearance'
gem 'clearance-deprecated_password_strategies'
gem 'daemons'
gem 'delayed_job'
gem 'delayed_job_active_record'

gem 'newrelic_rpm'
gem 'newrelic-redis'

gem 'sass-rails',   '~> 5.0.0'
gem 'coffee-rails', '~> 4.1'
gem 'uglifier', '>= 1.0.3'

group :development, :test do
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
  gem 'timecop'
end

group :development, :deploy do
  gem 'capistrano', '~> 3.0', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  gem 'capistrano-git-submodule-strategy', '~> 0.1.17', require: false
end

platforms :jruby do
  gem 'jruby-openssl'
end
