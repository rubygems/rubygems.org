set :stages, %w(vagrant staging production)
set :default_stage, "staging"

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'capistrano-notification'

notification.irc do |irc|
  irc.host    'chat.freenode.net'
  irc.channel '#rubygems'
  irc.message { "#{local_user} deployed rubygems.org @ https://github.com/rubygems/rubygems.org/commit/#{fetch(:current_revision)} to #{stage} (#{roles[:app].servers.compact.map(&:host).join(', ')})" }
end

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
after "deploy:create_symlink", "deploy:symlink_database_yml", "deploy:symlink_secret_settings"

namespace :deploy do

  desc "Symlink database.yml for this environment"
  task :symlink_database_yml, :roles => :app do
    run "ln -fs #{shared_path}/database.yml #{release_path}/config/database.yml"
  end

  desc "Symlink secret settings for this environment"
  task :symlink_secret_settings, :roles => :app do
    run "ln -fs #{shared_path}/secret.rb #{release_path}/config/secret.rb"
  end

  desc "Restart unicorn and delayed_job"
  task :restart, :roles => :restart do
    sudo "service unicorn restart"
    sudo "service delayed_job restart"
  end

end
