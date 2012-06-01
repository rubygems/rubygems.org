role :app, "b1.rubygems.org"
role :web, "b1.rubygems.org"
role :db,  "b1.rubygems.org", :primary => true

set :branch,    "production"
set :deploy_to, "/var/www/rubycentral/gemcutter.org/"
