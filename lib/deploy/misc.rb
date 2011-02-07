namespace :deploy do
  desc "Move in database.yml for this environment"
  task :move_in_database_yml, :roles => :app do
    run "cp #{deploy_to}/shared/config/database.yml #{current_path}/config/"
  end

  desc "Move in secret settings for this environment"
  task :move_in_secret_settings, :roles => :app do
    run "cp #{deploy_to}/shared/config/secret.rb #{current_path}/config/secret.rb"
    run "cp #{deploy_to}/shared/config/newrelic.yml #{current_path}/config/newrelic.yml"
  end

  task :set_config_for_pg_gem, :roles => [:app, :db] do
    run "cd #{current_path} && bundle config build.pg --with-pg-config=/usr/local/pgsql/bin/pg_config --no-rdoc --no-ri"
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

