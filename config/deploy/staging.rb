server 'deploy@app01.staging.rubygems.org', :app, :db, :primary => true
role :restart, 'app01.staging.rubygems.org', :no_release => true
set :branch, ENV['BRANCH'] || 'master'

namespace :deploy do
  desc "For the staging environment, symlink a robots.txt that blocks robots from the entire site"
  task :symlink_staging_robots_txt, :roles => :app do
    run "ln -fs #{release_path}/public/robots.txt.staging #{release_path}/public/robots.txt"
  end
end

after "deploy:symlink", "deploy:symlink_staging_robots_txt"
