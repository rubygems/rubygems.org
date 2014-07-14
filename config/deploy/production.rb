server 'deploy@app02.production.rubygems.org', :app, :db, :primary => true
role :restart, 'app02.production.rubygems.org', :no_release => true
set :branch, 'master'
