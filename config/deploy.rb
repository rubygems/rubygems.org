# config valid only for current version of Capistrano
lock '3.7.1'

set :application, 'rubygems'
set :deploy_to, '/applications/rubygems'
set :repo_url, 'https://github.com/rubygems/rubygems.org.git'
set :branch, ENV['SHA'] || ENV['BRANCH'] || 'master'
set :pty, true
set :assets_roles, [:app]
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/cache', 'tmp/sockets')
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secret.rb', 'config/versions.list')
set :git_wrapper_path, lambda {
  # Try to avoid permissions issues when multiple users deploy the same app
  # by using different file names in the same dir for each deployer and stage.
  suffix = [:application, :stage, :local_user].map { |key| fetch(key).to_s }.join("-").gsub(/[\(\)\s+]/, "-")
  "#{fetch(:tmp_dir)}/git-ssh-#{suffix}.sh"
}

namespace :deploy do
  desc 'Remove git cache for clean deploy'
  task :clean_git_cache do
    on roles(:app) do
      execute :rm, "-rf #{repo_path}"
    end
  end

  desc 'Restart unicorn and delayed_job'
  task :restart do
    on roles(:app) do
      execute :sudo, 'service unicorn restart'
    end
    on roles(:jobs) do
      execute :sudo, 'sv -w 30 restart delayed_job'
      execute :sudo, 'sv -w 30 restart shoryuken'
    end
  end
  after :publishing, :'deploy:restart'
end

namespace :maintenance do
  desc 'Enable maintenance mode'
  task :enable do
    on roles(:lb) do
      execute :sudo, 'ln -s /etc/nginx/maintenance.html /var/www/rubygems/maintenance.html'
    end
  end

  desc 'Disable maintenance mode'
  task :disable do
    on roles(:lb) do
      execute :sudo, 'rm /var/www/rubygems/maintenance.html'
    end
  end
end

namespace :memcached do
  desc "Flushes memcached instance cache"
  task :flush do
    on roles(:app, select: :primary) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'memcached:flush'
        end
      end
    end
  end
end
