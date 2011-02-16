source :rubygems
gem "rails", "3.0.3"
gem "rack",  "1.2.1"
gem "mail",  "2.2.15"

gem "clearance",         "0.9.0.rc9"
gem "fog",               "0.3.25"
gem "gchartrb",          "0.8",   :require => "google_chart"
gem "gravtastic",        "2.1.3"
gem "high_voltage",      "0.9.1"
gem "hoptoad_notifier",  "2.2.0"
gem "json",              "1.2.0"
gem "newrelic_rpm",      "2.13.0.beta6"
gem "paul_revere",       "0.1.5"
gem "rack-maintenance",  "0.3.0", :require => "rack/maintenance"
gem "redis",             "2.0.1"
gem "rest-client",       "1.0.3", :require => "rest_client"
gem "sinatra",           "1.0"
gem "sunspot_rails",     "1.2.1"
gem "system_timer",      "1.0"
gem "will_paginate",     "3.0.pre2"
gem "xml-simple",        "1.0.12"

# These gems suck and do stupid things when in maintenance mode
group :development, :test, :staging, :demo, :production do
  gem "delayed_job",             "2.1.2"
  gem "validates_url_format_of", "0.1.0"
end

group :development, :test do 
  gem 'silent-postgres', "0.0.7"
end

gem "pg", "0.8.0"

group :test do
  gem "cucumber-rails",     "0.3.2"
  gem "factory_girl_rails", "1.0"

  gem "database_cleaner",   "0.5.2"
  gem "launchy",            "0.3.7"
  gem "nokogiri",           "1.4.3.1"
  gem "rack-test",          "0.5.7", :require => "rack/test"
  gem "redgreen",           "1.2.2"
  gem "rr",                 "0.10.11"
  gem "shoulda",            "2.11.1"
  gem "timecop",            "0.3.5"
  gem "webrat",             "0.5.3"
  gem "webmock",            "1.6.2"

end
