server 'app01.staging.rubygems.org', user: 'deploy', roles: %w[app jobs db], primary: true
server 'lb01.staging.rubygems.org', user: 'deploy', roles: %w[lb], no_release: true
set :bundle_flags, ''

namespace :deploy do
  after :finishing, :symlink_staging_robots_txt do
    on roles(:app) do
      execute :ln, "-fs #{release_path}/public/robots.txt.staging #{release_path}/public/robots.txt"
    end
  end
end
