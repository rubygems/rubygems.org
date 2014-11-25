server 'deploy@app02.production.rubygems.org', :app, :db, :primary => true
server 'deploy@app03.production.rubygems.org', :app, :db
role :restart, 'app02.production.rubygems.org', 'app03.production.rubygems.org', :no_release => true
set :branch, 'production'
