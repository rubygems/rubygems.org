source 'https://rubygems.org'

# https://github.com/mime-types/ruby-mime-types/issues/94
# This can be removed once all gems depend on > 3.0
gem 'mime-types', '~> 2.6'

gem 'rails', '~> 4.2.5'
gem 'rails-i18n'

gem 'autoprefixer-rails'
gem 'aws-sdk-core'
gem 'bootscale'
gem 'clearance'
gem 'clearance-deprecated_password_strategies'
## TODO maybe remove deamons?
gem 'daemons'
gem 'dalli'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'doorkeeper'
gem 'dynamic_form'
## TODO maybe remove deamons?
gem 'gchartrb'
gem 'gravtastic'
gem 'high_voltage'
gem 'highline'
gem 'honeybadger'
gem 'http_accept_language'
gem 'jquery-rails'
gem 'mail'
gem 'multi_json'
gem 'newrelic-redis'
gem 'newrelic_rpm'
gem 'paul_revere', '~> 2.0'
gem 'pg'
gem 'psych', '~> 2.0.12'
gem 'rack'
gem 'rdoc'
gem 'redis'
gem 'rest-client'
gem 'statsd-instrument', '~> 2.0.6'
gem 'uglifier', '>= 1.0.3'
gem 'unicorn'
gem 'validates_formatting_of'
gem 'will_paginate'
gem 'elasticsearch-model', '~> 0.1.7'
gem 'elasticsearch-rails', '~> 0.1.7'
gem 'elasticsearch-dsl', '~> 0.1.2'
gem 'yajl-ruby'

group :development, :test do
  gem 'rubocop'
  gem 'toxiproxy', '~> 0.1.3'
end

group :development do
  gem 'quiet_assets'
  gem 'rails-erd'
end

group :test do
  gem 'minitest'
  gem 'capybara'
  gem 'factory_girl_rails'
  gem 'rack-test'
  gem 'mocha'
  gem 'bourne'
  gem 'shoulda'
end

group :development, :deploy do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-bundler', '~> 1.1'
end

platforms :jruby do
  gem 'jruby-openssl'
end
