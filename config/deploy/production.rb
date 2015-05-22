server 'app02.production.rubygems.org', user: 'deploy', roles: %w{app db}
server 'app03.production.rubygems.org', user: 'deploy', roles: %w{app}
set :branch, 'master'
