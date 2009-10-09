clear_sources
bundle_path "vendor/bundler_gems"

source "http://gemcutter.org"
source "http://gems.github.com"

gem "rails", "2.3.4"

gem "clearance"
gem "will_paginate"
gem "sinatra"
gem "xml-simple"
gem "gchartrb", :require_as => "google_chart"
gem "ddollar-pacecar", "1.1.6", :require_as => "pacecar"

only :test do
  gem "shoulda"
  gem "factory_girl"
  gem "webrat"
  gem "cucumber", "0.3.101"
  gem "rr"
  gem "redgreen"
  gem "fakeweb"
  gem "rack-test", :require_as => "rack/test"
end

only :production do
  gem "rack-cache",        :require_as => "rack/cache"
  gem "aws-s3",            :require_as => "aws/s3"
  gem "ambethia-smtp-tls", :require_as => "smtp-tls"
  gem "memcache-client",   :require_as => "memcache"
end
