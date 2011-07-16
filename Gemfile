source 'http://rubygems.org'

gem 'rails', '3.0.9'

gem 'clearance'
gem 'fog'
gem 'gchartrb',         '0.8',   :require => 'google_chart'
gem 'gravtastic'
gem 'high_voltage'
gem 'hoptoad_notifier', '2.4.1'
gem 'mail'
gem 'newrelic_rpm',     '2.13.4'
gem 'paul_revere',      '0.1.5'
gem 'pg'
gem 'rack'
gem 'rack-maintenance', :require => 'rack/maintenance'
gem 'redis',            '2.1.1'
gem 'rest-client',      '1.0.3', :require => 'rest_client'
gem 'sinatra',          '1.2.1'
gem 'will_paginate',    '3.0.pre2'
gem 'xml-simple',       '1.0.12'
gem 'yajl-ruby',        '0.8.2', :require => 'yajl/json_gem'

platforms :ruby_18 do
  gem 'system_timer'
end

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :production do
  gem 'delayed_job',             '2.1.2'
  gem 'validates_url_format_of', '0.1.0'
end

group :development, :test do
  gem 'silent-postgres', '0.0.7'
end

group :test do
  gem 'cucumber-rails'
  gem 'database_cleaner',   '0.5.2'
  gem 'factory_girl_rails', '1.0'
  gem 'fakeweb',            '1.2.6'
  gem 'launchy',            '0.3.7'
  gem 'nokogiri'
  gem 'rack-test',          '0.5.7', :require => 'rack/test'
  gem 'redgreen',           '1.2.2'
  gem 'rr',                 '0.10.11'
  gem 'shoulda',            '2.11.1'
  gem 'timecop',            '0.3.5'
  gem 'webmock',            '0.7.3'
  gem 'webrat',             '0.5.3'
end
