server 'app01.staging.rubygems.org', user: 'deploy', roles: %w(app db)
server 'lb01.staging.rubygems.org', user: 'deploy', roles: %w(lb), no_release: true
set :branch, ENV['BRANCH'] || 'master'
set :bundle_flags, ''

namespace :deploy do
  after :finishing, :symlink_staging_robots_txt do
    on roles(:app) do
      execute :ln, "-fs #{release_path}/public/robots.txt.staging #{release_path}/public/robots.txt"
    end
  end
end
