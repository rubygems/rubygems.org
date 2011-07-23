source 'http://rubygems.org'

gem 'rails', '~> 3.0.9'

gem 'clearance', '~> 0.9.1'
gem 'fog'
gem 'gchartrb', :require => 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'hoptoad_notifier'
gem 'mail'
gem 'newrelic_rpm'
gem 'paul_revere'
gem 'pg'
gem 'rack'
gem 'rack-maintenance', :require => 'rack/maintenance'
gem 'rdoc'
gem 'redis'
gem 'rest-client', :require => 'rest_client'
gem 'sinatra'
gem 'will_paginate', '~> 3.0.pre2'
gem 'xml-simple'
gem 'yajl-ruby', :require => 'yajl/json_gem'

platforms :ruby_18 do
  gem 'system_timer'
end

platforms :jruby do
  gem 'jruby-openssl'
end

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :production do
  gem 'delayed_job'
  gem 'validates_url_format_of'
end

group :development, :test do
  gem 'silent-postgres'
end

group :test do
  gem 'cucumber-rails', '~> 1.0.2'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'nokogiri'
  gem 'rack-test', :require => 'rack/test'
  gem 'rr'
  gem 'shoulda'
  gem 'timecop'
  gem 'webmock'
  gem 'webrat', '~> 0.5.3'
end
