set :stages, %w(staging production)
set :default_stage, "staging"

require 'capistrano/ext/multistage'

default_run_options[:pty] = true

set :ssh_options, { :forward_agent => true }

set :application, "gemcutter"
set(:rails_env) { "#{stage}"}

# Note that this requires you run 'ssh-add' on your workstation in order to
# add your private key to the ssh agent.  If that's not good for you, just uncomment the 
# "set :deploy_via, :copy" and comment "set :deploy_via, :remote_cache"
set :scm, :git
set :repository, "git://github.com/rubygems/gemcutter"
set :repository_cache, "git_cache"
set :git_enable_submodules, 1
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :use_sudo, false

set :group, "rubycentral"
set :user, "rubycentral"

set :ree_path, "/opt/ruby-enterprise-1.8.7-2010.02/bin"

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  desc "Move in database.yml for this environment"
  task :move_in_database_yml, :roles => :app do
    run "cp #{deploy_to}/shared/system/database.yml #{current_path}/config/"
  end

  desc "Run gem bundle"
  task :bundle, :roles => :app do
    env = "PATH=/usr/local/pgsql/bin:/usr/local/bin:/bin:/usr/bin RAILS_ENV=#{rails_env} #{ree_path}"
    run "#{env}/bundle install --gemfile #{release_path}/Gemfile --path #{fetch(:bundle_dir, "#{shared_path}/bundle")} --deployment --without development test"
  end

  desc "Migrate with bundler"
  task :migrate_with_bundler, :roles => :app do
    run "cd #{release_path} && #{ree_path}/rake db:migrate RAILS_ENV=#{rails_env}"
  end

  # Surely there's a better way to do this.  But it's eluding me at the moment.
  desc "Move in secret settings for this environment"
  task :move_in_secret_settings, :roles => :app do
    run "cp #{deploy_to}/shared/system/secret.rb #{current_path}/config/secret.rb"
    run "cp #{deploy_to}/shared/system/newrelic.yml #{current_path}/config/newrelic.yml"
  end
end

namespace :maintenance do
  desc "Go to maintenance mode"
  task :on, :roles => :app do
    run "touch #{current_path}/tmp/maintenance_mode"
    deploy.restart
  end
  desc "Back to normal non-maintenance mode"
  task :off, :roles => :app do
    run "rm -f #{current_path}/tmp/maintenance_mode"
    deploy.restart
  end
end

namespace :delayed_job do
  desc "Start delayed_job process" 
  task :start, :roles => :app do
    run "sudo monit start delayed_job_#{rails_env}" 
  end

  desc "Stop delayed_job process" 
  task :stop, :roles => :app do
    run "sudo monit stop delayed_job_#{rails_env}" 
  end

  desc "Restart delayed_job process" 
  task :restart, :roles => :app do
    run "sudo monit stop delayed_job_#{rails_env}" 
    sleep 5
    run "sudo monit start delayed_job_#{rails_env}" 
  end
end

after "deploy:start", "delayed_job:start" 
after "deploy:stop", "delayed_job:stop" 
after "deploy:restart", "delayed_job:restart"

after "deploy:update_code", "deploy:bundle"
after "deploy", "deploy:migrate_with_bundler"
after "deploy", "deploy:cleanup"
after "deploy:symlink", "deploy:move_in_database_yml", "deploy:move_in_secret_settings"



Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end
