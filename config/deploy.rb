set :stages, %w(vagrant staging production)
set :default_stage, "staging"

require 'capistrano/ext/multistage'
require 'bundler/capistrano'

default_run_options[:pty] = true
set :ssh_options, { :forward_agent => true }
set :application, "rubygems"
set(:rails_env) { "#{stage}"}
set :deploy_to, "/applications/rubygems"
set :bundle_cmd, "/usr/local/bin/bundle"
set :scm, :git
set :repository, "https://github.com/rubygems/rubygems.org.git"
set :repository_cache, "git_cache"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :use_sudo, false
set :group, "deploy"

after "deploy", "deploy:migrate"
after "deploy", "deploy:cleanup"
after "deploy:create_symlink", "deploy:move_in_database_yml", "deploy:move_in_secret_settings"

namespace :deploy do

  desc "Move in database.yml for this environment"
  task :move_in_database_yml, :roles => :app do
    run "cp #{deploy_to}/shared/database.yml #{current_path}/config/"
  end

  desc "Move in secret settings for this environment"
  task :move_in_secret_settings, :roles => :app do
    run "cp #{deploy_to}/shared/secret.rb #{current_path}/config/secret.rb"
  end

  desc "Restart unicorn and delayed_job"
  task :restart, :roles => :restart do
    sudo "service unicorn restart"
    sudo "service delayed_job restart"
  end

end
