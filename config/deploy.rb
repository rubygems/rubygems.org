set :application, "gemcutter"
set :server_ip,   "gemcutter.org"
set :root_path,   "/home/rails/gemcutter"

ssh_options[:port] = 1908
set :port, 1908
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
