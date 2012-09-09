source 'https://rubygems.org'

gem 'rails', '~> 3.2.7'

gem 'airbrake'
gem 'builder', '> 3.0.1'
gem 'clearance', '~> 0.16'
gem 'dynamic_form'
gem 'excon'
gem 'fog', '~> 1.4.0'
gem 'gchartrb', :require => 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'highline'
gem 'jquery-rails'
gem 'mail'
gem 'memcached'
gem 'multi_json'
gem 'paul_revere'
gem 'pg'
gem 'puma'
gem 'rack'
gem 'rack-maintenance', :require => 'rack/maintenance'
gem 'rdoc'
gem 'redis'
gem 'rest-client', :require => 'rest_client'
gem 'sinatra'
gem 'validates_formatting_of', '>= 0.3'
gem 'will_paginate'
gem 'xml-simple'
gem 'yajl-ruby', :require => 'yajl'

# enable if on heroku, make sure to toss this into an initializer:
#     Rails.application.config.middleware.use HerokuAssetCacher
#gem 'heroku_asset_cacher', :git => "git@github.com/qrush/heroku_asset_cacher"

group :development do
  gem 'capistrano-ext'
  gem 'rails-erd'
  gem 'rvm'
  gem 'rvm-capistrano'
  gem 'pry'
end

group :test do
  gem 'capybara'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'nokogiri'
  gem 'rack-test', :require => 'rack/test'
  gem 'rr'
  gem 'shoulda', :require => false
  #gem 'test-unit', :require => 'test/unit'
  gem 'timecop'
  gem 'webmock'
end

# For some reason, including these gems in the maintenance environment enables
# maintenance mode
group :development, :test, :staging, :production do
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
