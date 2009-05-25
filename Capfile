load 'deploy' if respond_to?(:namespace) # cap2 differentiator

set :application, "gemcutter"
set :server_ip, "gemcutter.org"
set :deploy_to, "/home/rails/gemcutter"

ssh_options[:port] = 1337
set :port, 1337
set :user, "rails"
role :app, server_ip
role :web, server_ip
role :db,  server_ip, :primary => true

set :scm, "git"
set :repository,  "git://github.com/qrush/#{application}.git"
set :deploy_via, :remote_cache
set :ssh_options, { :forward_agent => true }

namespace :deploy do
  task :stop, :roles => [:app] do
    puts "Use the deploy:restart task to restart the Rails application" 
  end
  task :start, :roles => [:app] do
    puts "Use the deploy:restart task to restart the Rails application" 
  end
  task :restart, :roles => [:app] do
    run "touch #{current_path}/tmp/restart.txt" 
  end

  task :setup do
    run "rm -rf #{release_path}/server"
    run "ln -s /home/rails/gems.gemcutter #{release_path}/server"
    run "ln -s /home/rails/cache #{release_path}/cache"
  end
end

after "deploy:finalize_update", "deploy:setup"
