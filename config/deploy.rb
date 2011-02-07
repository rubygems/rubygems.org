set :stages, %w(staging production)
set :default_stage, "staging"

require 'capistrano/ext/multistage'
require 'bundler/capistrano'

default_run_options[:pty] = true
set :ssh_options, { :forward_agent => true }
set :application, "gemcutter"
set(:rails_env) { "#{stage}"}

# Note that this requires you run 'ssh-add' on your workstation in order to
# add your private key to the ssh agent.  If that's not good for you, just uncomment the 
# "set :deploy_via, :copy" and comment "set :deploy_via, :remote_cache"
set :scm, :git
set :repository, "git://github.com/rubygems/#{application}"
set :repository_cache, "git_cache"
set :git_enable_submodules, 1
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :use_sudo, false
set :group, "rubycentral"
set :user, "rubycentral"

after "deploy", "deploy:migrate"
after "deploy:update", "bluepill:quit", "bluepill:start"
after "deploy", "deploy:cleanup"
after "deploy:symlink", "deploy:move_in_database_yml", "deploy:move_in_secret_settings"
before "bundle:install", "deploy:set_config_for_pg_gem"
