source 'https://rubygems.org'
# ruby '2.0.0'

gem 'rails', '~> 4.1.8'

gem 'builder'
gem 'dynamic_form'
gem 'excon'
gem 'fog', '= 1.15.0'
gem 'gchartrb', require: 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'highline'
gem 'jquery-rails'
gem 'librato-rails'
gem 'mail'
gem 'dalli'
gem 'multi_json'
gem 'paul_revere'
gem 'pg'
gem 'puma'
gem 'rack'
gem 'rack-maintenance', require: 'rack/maintenance'
gem 'rdoc'
gem 'redis'
gem 'rest-client', require: 'rest_client'
gem 'sinatra'
gem 'unicorn'
gem 'unf'
gem 'validates_formatting_of'
gem 'will_paginate'
gem 'xml-simple'
gem 'yajl-ruby', require: 'yajl'
gem 'autoprefixer-rails'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

# enable if on heroku, make sure to toss this into an initializer:
#     Rails.application.config.middleware.use HerokuAssetCacher
#gem 'heroku_asset_cacher', git: "git@github.com/qrush/heroku_asset_cacher"

group :development do
  gem 'capistrano', '~> 2.0'
  gem 'capistrano-notification'
  gem 'rails-erd'
end

group :test do
  gem 'capybara'
  gem 'cucumber-rails', require: false
  gem 'database_rewinder'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'nokogiri'
  gem 'rack-test', require: 'rack/test'
  gem 'rr', '1.1.0.rc1' , require: false
  gem 'shoulda', require: false
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'pry'
end

# For some reason, including these gems in the maintenance environment enables
# maintenance mode
group :development, :test, :staging, :production do
  gem 'minitest'
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

