server 'deploy@app01.staging.rubygems.org', :app, :db, :primary => true
role :restart, 'app01.staging.rubygems.org', :no_release => true
set :branch, 'staging'
# set :gateway, 'bastion01.staging.rubygems.org'

# namespace :deploy do
#   desc "For the staging environment, move in a robots.txt that blocks robots from the entire site"
#   task :move_in_staging_robots_txt, :roles => :app do
#     run "cp #{deploy_to}/shared/config/robots.txt #{current_path}/public/robots.txt"
#   end
# end

# after "deploy:symlink", "deploy:move_in_staging_robots_txt"
