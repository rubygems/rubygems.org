source :rubygems

gem "rails", "3.0.0"
gem "rack",  "1.2.1"

gem "clearance",         "0.9.0.rc9"
gem "fog",               "0.2.14"
gem "gchartrb",          "0.8",   :require => "google_chart"
gem "gravtastic",        "2.1.3"
gem "high_voltage",      "0.9.1"
gem "hoptoad_notifier",  "2.2.0"
gem "json",              "1.2.0"
gem "newrelic_rpm",      "2.13.0.beta6"
gem "rack-maintenance",  "0.3.0", :require => "rack/maintenance"
gem "redis",             "2.0.1"
gem "rest-client",       "1.0.3", :require => "rest_client"
gem "sinatra",           "1.0"
gem "will_paginate",     "3.0.pre2"
gem "xml-simple",        "1.0.12"

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :production do
  gem 'daemons',     :git => 'git://github.com/ghazel/daemons.git'
  gem 'delayed_job', :git => 'git://github.com/collectiveidea/delayed_job.git'

  gem 'validates_url_format_of', '0.1.0'
end

gem "pg", "0.8.0"
# gem "mysql", "2.8.1"

group :test do
  gem "cucumber-rails",     "0.3.2"
  gem "factory_girl_rails", "1.0"

  gem "database_cleaner",   "0.5.2"
  gem "fakeweb",            "1.2.6"
  gem "nokogiri",           "1.4.1"
  gem "rack-test",          "0.5.4", :require => "rack/test"
  gem "rr",                 "1.0.0"
  gem "shoulda",            "2.11.1"
  gem "treetop",            "1.4.5"
  gem "webrat",             "0.5.3"
  gem "webmock",            "0.7.3"

  gem "test-unit", "2.1.1"
  gem "mynyml-redgreen", :git => 'git://github.com/mynyml/redgreen.git', :require => 'redgreen'
end
