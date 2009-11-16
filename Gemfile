clear_sources
bundle_path "vendor/bundler_gems"

source "http://gemcutter.org"
source "http://gems.github.com"

gem "rails", "2.3.4"
gem "rack",  "1.0.1"

gem "clearance",       "0.8.2"
gem "will_paginate",   "2.3.11"
gem "sinatra",         "0.9.4"
gem "xml-simple",      "1.0.12"
gem "gchartrb",        "0.8",   :require_as => "google_chart"
gem "ddollar-pacecar", "1.1.6", :require_as => "pacecar"
gem "net-scp",         "1.0.2"
gem "rack-maintenance", "0.3.0", :require_as => "rack/maintenance"
gem "mikehale-daemons", "1.0.12.4", :require_as => "daemons"

only :test do
  gem "shoulda",      "2.10.2"
  gem "factory_girl", "1.2.3"
  gem "webrat",       "0.5.3"
  gem "cucumber",     "0.3.101"
  gem "rr",           "0.10.4"
  gem "redgreen",     "1.2.2"
  gem "fakeweb",      "1.2.6"
  gem "rack-test",    "0.5.0", :require_as => "rack/test"
end

only [:staging, :production] do
  gem "rack-cache",        "0.5.2", :require_as => "rack/cache"
  gem "aws-s3",            "0.6.2", :require_as => "aws/s3"
  gem "ambethia-smtp-tls", "1.1.2", :require_as => "smtp-tls"
  gem "memcache-client",   "1.7.5", :require_as => "memcache"
end
