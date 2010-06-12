role :app, "rubycentral.org"
role :web, "rubycentral.org"
role :db,  "rubycentral.org", :primary => true

set :branch,    "production"
set :deploy_to, "/var/www/rubycentral/gemcutter.org/"
