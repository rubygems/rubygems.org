role :app, "b1.rubycentral.org"
role :web, "b1.rubycentral.org"
role :db,  "b1.rubycentral.org", :primary => true

set :branch,    "production"
set :deploy_to, "/var/www/rubycentral/gemcutter.org/"
