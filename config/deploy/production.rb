server 'app01.production.rubygems.org', user: 'deploy', roles: %w(app)
server 'app02.production.rubygems.org', user: 'deploy', roles: %w(app db)
server 'app03.production.rubygems.org', user: 'deploy', roles: %w(app)
server 'lb03.production.rubygems.org', user: 'deploy', roles: %w(lb), no_release: true
set :branch, 'master'
