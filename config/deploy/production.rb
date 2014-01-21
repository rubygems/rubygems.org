server 'deploy@app02-aws.rubygems.org', :app, :db, :primary => true
role :restart, 'app02-aws.rubygems.org', :no_release => true
set :branch, 'master'
