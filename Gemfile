source 'https://rubygems.org'

gem 'rails', '~> 3.0.10'

gem 'airbrake'
gem 'clearance', '~> 0.13.2'
gem 'excon'
gem 'fog'
gem 'gchartrb', :require => 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'jquery-rails'
gem 'mail'
gem 'multi_json'
gem 'newrelic_rpm'
gem 'paul_revere'
gem 'pg'
gem 'rack'
gem 'rack-maintenance', :require => 'rack/maintenance'
gem 'rdoc'
gem 'redis'
gem 'rest-client', :require => 'rest_client'
gem 'sinatra'
gem 'validates_formatting_of', '>= 0.3.0'
gem 'will_paginate'
gem 'xml-simple'
gem 'yajl-ruby', :require => 'yajl'

group :development do
  gem 'capistrano-ext'
  gem 'rails-erd'
  gem 'rvm'
  gem 'pry'
end

group :development, :test do
  gem 'silent-postgres'
  gem 'guard'
  gem 'guard-cucumber'
  gem 'guard-bundler'
end

group :test do
  gem 'capybara'
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'nokogiri'
  gem 'rack-test', :require => 'rack/test'
  gem 'redgreen', :platforms => :ruby_18
  gem 'rr'
  gem 'shoulda'
  gem 'timecop'
  gem 'webmock'
end

# For some reason, including these gems in the maintenance environment enables
# maintenance mode
group :development, :test, :staging, :production do
  gem 'daemons'
  gem 'delayed_job', '~> 3.0.0.pre'
  gem 'delayed_job_active_record'
end

platforms :jruby do
  gem 'jruby-openssl'
end

platforms :ruby_18 do
  gem 'system_timer'
end
