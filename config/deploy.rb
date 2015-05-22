# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'rubygems'
set :deploy_to, '/applications/rubygems'
set :repo_url, 'https://github.com/rubygems/rubygems.org.git'
set :scm, :git
set :git_strategy, Capistrano::Git::SubmoduleStrategy
set :pty, true
set :assets_roles, [:app]
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/cache', 'tmp/sockets')
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secret.rb')

namespace :deploy do

  desc 'Remove git cache for clean deploy'
  task :clean_git_cache do
    on roles(:app) do
      execute :rm, "-rf #{repo_path}"
    end
  end

  desc 'Restart unicorn and delayed_job'
  task :restart do
    on roles(:app) do |host|
      execute :sudo, 'service unicorn restart'
      execute :sudo, 'service delayed_job restart'
    end
  end
  after :publishing, :'deploy:restart'

end
