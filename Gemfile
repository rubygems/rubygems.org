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
gem 'will_paginate'
gem 'xml-simple'
gem 'yajl-ruby', :require => 'yajl/json_gem'

platforms :ruby_19 do
  gem 'psych'
end

platforms :ruby_18 do
  gem 'system_timer'
  group :test do
    gem 'redgreen'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end

group :development do
  gem 'rails-erd'
end

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :production do
  gem 'delayed_job'
  gem 'validates_url_format_of', '~> 0.1.2'
end

group :development, :test do
  gem 'silent-postgres'
end

group :test do
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'nokogiri'
  gem 'rack-test', :require => 'rack/test'
  gem 'rr'
  gem 'shoulda'
  gem 'timecop'
  gem 'webmock'
end
