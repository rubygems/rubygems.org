source 'https://rubygems.org'

# https://github.com/mime-types/ruby-mime-types/issues/94
# This can be removed once all gems depend on > 3.0
gem 'mime-types', '~> 2.6', require: false

gem 'rails', '~> 4.2.5', require: false
gem 'rails-i18n', require: false

gem 'autoprefixer-rails', require: false
gem 'aws-sdk-core', require: false
gem 'bootscale', require: false
gem 'clearance', require: false
gem 'clearance-deprecated_password_strategies', require: false
## TODO maybe remove deamons?
gem 'daemons', require: false
gem 'dalli', require: false
gem 'delayed_job', require: false
gem 'delayed_job_active_record', require: false
gem 'doorkeeper', require: false
gem 'dynamic_form', require: false
## TODO maybe remove deamons?
gem 'gchartrb', require: false
gem 'gravtastic', require: false
gem 'high_voltage', require: false
gem 'highline', require: false
gem 'honeybadger', require: false
gem 'http_accept_language'
gem 'jquery-rails', require: false
gem 'mail', require: false
gem 'multi_json', require: false
gem 'newrelic-redis', require: false
gem 'newrelic_rpm', require: false
gem 'paul_revere', '~> 2.0', require: false
gem 'pg', require: false
gem 'psych', '~> 2.0.12', require: false
gem 'rack', require: false
gem 'rdoc', require: false
gem 'redis', require: false
gem 'rest-client', require: false
gem 'statsd-instrument', '~> 2.0.6', require: false
gem 'uglifier', '>= 1.0.3', require: false
gem 'unicorn', require: false
gem 'validates_formatting_of', require: false
gem 'will_paginate', require: false
gem 'elasticsearch-model', '~> 0.1.7', require: false
gem 'elasticsearch-rails', '~> 0.1.7', require: false
gem 'elasticsearch-dsl', '~> 0.1.2', require: false
gem 'yajl-ruby', require: false

group :development, :test do
  gem 'rubocop', require: false
  gem 'toxiproxy', '~> 0.1.3', require: false
end

group :development do
  gem 'quiet_assets'
  gem 'rails-erd'
end

group :test do
  gem 'minitest', require: false
  gem 'capybara', require: false
  gem 'factory_girl_rails', require: false
  gem 'rack-test', require: false
  gem 'mocha', require: false
  gem 'bourne', require: false
  gem 'shoulda', require: false
end

group :development, :deploy do
  gem 'capistrano', '~> 3.0', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
end

platforms :jruby do
  gem 'jruby-openssl'
end
