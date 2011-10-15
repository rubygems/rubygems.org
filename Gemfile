source 'http://rubygems.org'

gem 'rails', '~> 3.0.10'

gem 'clearance'
gem 'fog'
gem 'gchartrb', :require => 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'hoptoad_notifier'
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
gem 'will_paginate'
gem 'xml-simple'
gem 'yajl-ruby', :require => 'yajl'

group :development do
  gem 'rails-erd'
  gem 'pry'
end

group :development, :test do
  gem 'silent-postgres'
  gem 'guard'
  gem 'guard-cucumber'
  gem 'guard-bundler'
end

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :production do
  gem 'delayed_job', '3.0.0.pre'
  gem 'delayed_job_active_record'
  gem 'validates_url_format_of'
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

platforms :jruby do
  gem 'jruby-openssl'
end

platforms :ruby_18 do
  gem 'system_timer'
end
