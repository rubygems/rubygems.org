set :deploy_to, "/var/www/rubycentral/gemcutter.org/"

role :app, "rubycentral.org"
role :web, "rubycentral.org"
role :db,  "rubycentral.org", :primary => true

