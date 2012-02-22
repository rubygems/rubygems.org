source 'https://rubygems.org'

gem 'rails', '~> 3.2.1'
gem 'sinatra', '~> 1.3'
gem 'pg', '~> 0.13'

gem 'excon', '~> 0.9'
gem 'clearance', '~> 0.15'
gem 'fog', '~> 1.1'
gem 'gchartrb', '~> 0.8', require: 'google_chart'
gem 'gravtastic', '~> 3.2'
gem 'high_voltage', '~> 1.0'
gem 'airbrake', '~> 3.0'
gem 'mail', '~> 2.4'
gem 'paul_revere', '~> 0.2'
gem 'rack-maintenance', '~> 0.3', require: 'rack/maintenance'
gem 'redis', '~> 2.2'
gem 'rest-client', '~> 1.6', require: 'rest_client'
gem 'will_paginate', '~> 3.0'
gem 'nokogiri', '~> 1.5'
gem 'xml-simple', '~> 1.1'
gem 'multi_json', '~> 1.0.3'
gem 'yajl-ruby', '~> 1.1', require: 'yajl/json_gem'
gem 'validates_formatting_of', '~> 0.4'
gem 'jquery-rails', '~> 2.0'

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :production do
  gem 'daemons', '~> 1.1'
  gem 'delayed_job', '~> 3.0'
  gem 'delayed_job_active_record', '~> 0.3'
end

group :development, :test do
  gem 'silent-postgres', '~> 0.1'
end

group :production do
  gem 'newrelic_rpm', '~> 3.3'
end

group :development do
  gem 'capistrano-ext', '~> 1.2'
  gem 'rdoc', '~> 3.12'
  gem 'pry', '~> 0.9'
  gem 'rails-erd', '~> 0.4'
  gem 'guard', '~> 1.0'
  gem 'guard-cucumber', '~> 0.7'
end

group :test do
  gem 'rr', '~> 1.0'
  gem 'cucumber-rails', '~> 1.3'
  gem 'shoulda', '~> 2.11'
  gem 'capybara', '~> 1.1'
  gem 'rack-test', '~> 0.6', require: 'rack/test'
  gem 'factory_girl_rails', '~> 1.7'
  gem 'database_cleaner', '~> 0.7'
  gem 'timecop', '~> 0.3'
  gem 'webmock', '~> 1.8'
  gem 'launchy', '~> 2.0'
  gem 'multi_xml', '~> 0.4'
  gem 'ox', '~> 1.4'
end

group :assets do
  gem 'uglifier', '~> 1.2'
end

platforms :jruby do
  gem 'jruby-openssl', '~> 0.7'
end
