raise "No staging server setup yet!"
# server ".us-west-2.compute.amazonaws.com", :app, :db, :primary => true
# set :branch,    "staging"

# namespace :deploy do
#   desc "For the staging environment, move in a robots.txt that blocks robots from the entire site"
#   task :move_in_staging_robots_txt, :roles => :app do
#     run "cp #{deploy_to}/shared/config/robots.txt #{current_path}/public/robots.txt"
#   end
# end

# after "deploy:symlink", "deploy:move_in_staging_robots_txt"
