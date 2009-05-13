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
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
end
