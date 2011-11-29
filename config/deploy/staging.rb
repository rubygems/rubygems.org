role :app, "staging.gemcutter.org"
role :web, "staging.gemcutter.org"
role :db,  "staging.gemcutter.org", :primary => true

set :branch,     "staging"
set :deploy_to,  "/var/www/rubycentral/staging.gemcutter.org/"

namespace :deploy do
  desc "For the staging environment, move in a robots.txt that blocks robots from the entire site"
  task :move_in_staging_robots_txt, :roles => :app do
    run "cp #{deploy_to}/shared/config/robots.txt #{current_path}/public/robots.txt"
  end
end

after "deploy:symlink", "deploy:move_in_staging_robots_txt"
