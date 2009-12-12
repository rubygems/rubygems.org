set :deploy_to, "/var/www/rubycentral/staging.gemcutter.org/"

namespace :deploy do
  desc "For the staging environment, move in a robots.txt that blocks robots from the entire site"
  task :move_in_staging_robots_txt, :roles => :app do
    run "cp #{deploy_to}/shared/system/robots.txt #{current_path}/public/robots.txt"
  end
end

after "deploy:symlink", "deploy:move_in_staging_robots_txt"
