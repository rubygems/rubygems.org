source 'https://rubygems.org'

gem 'rails', '~> 4.1.9'
gem 'psych', '~> 2.0.12'
gem 'builder'
gem 'dynamic_form'
gem 'excon'
gem 'fog'
gem 'gchartrb', require: 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'highline'
gem 'honeybadger'
gem 'jquery-rails'
gem 'librato-rails'
gem 'mail'
gem 'dalli'
gem 'multi_json'
gem 'paul_revere'
gem 'pg'
gem 'rack'
gem 'rack-maintenance', require: 'rack/maintenance'
gem 'rdoc', '~> 3.12.2'
gem 'redis'
gem 'rest-client', require: 'rest_client'
gem 'sinatra'
gem 'statsd-instrument', '~> 2.0.6'
gem 'unicorn'
gem 'validates_formatting_of'
gem 'will_paginate'
gem 'xml-simple'
gem 'yajl-ruby', require: 'yajl'
gem 'autoprefixer-rails'

gem 'sass-rails',   '~> 4.0.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.0.3'

group :development do
  gem 'capistrano', '~> 2.0'
  gem 'capistrano-notification'
  gem 'rails-erd'
end

group :test do
  gem 'minitest', require: false
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'nokogiri'
  gem 'rack-test', require: 'rack/test'
  gem 'rr', require: false
  gem 'shoulda', require: false
  gem 'timecop'
end

group :development, :test do
  gem 'pry'
end

# For some reason, including these gems in the maintenance environment enables
# maintenance mode
group :development, :test, :staging, :production do
  gem 'clearance'
  gem 'daemons'
  gem 'delayed_job'
  gem 'delayed_job_active_record'

  gem 'newrelic_rpm'
  gem 'newrelic-redis'
end

group :recovery do
  gem "fakeredis"
end

platforms :jruby do
  gem 'jruby-openssl'
end
