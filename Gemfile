source 'http://rubygems.org'

gem 'rails', '3.0.9'

gem 'clearance'
gem 'fog'
gem 'gchartrb',         '0.8',   :require => 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'hoptoad_notifier'
gem 'mail'
gem 'newrelic_rpm'
gem 'paul_revere',      '0.1.5'
gem 'pg'
gem 'rack'
gem 'rack-maintenance', :require => 'rack/maintenance'
gem 'redis'
gem 'rest-client',      :require => 'rest_client'
gem 'sinatra',          '1.2.6'
gem 'will_paginate',    '3.0.pre2'
gem 'xml-simple'
gem 'yajl-ruby',        '0.8.2', :require => 'yajl/json_gem'

platforms :ruby_18 do
  gem 'system_timer'
end

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :production do
  gem 'delayed_job'
  gem 'validates_url_format_of', '0.1.0'
end

group :development, :test do
  gem 'silent-postgres'
end

group :test do
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'fakeweb'
  gem 'launchy'
  gem 'nokogiri'
  gem 'rack-test',          '0.5.7', :require => 'rack/test'
  gem 'redgreen',           '1.2.2'
  gem 'rr'
  gem 'shoulda',            '2.11.1'
  gem 'timecop',            '0.3.5'
  gem 'webmock',            '0.7.3'
  gem 'webrat',             '0.5.3'
end
