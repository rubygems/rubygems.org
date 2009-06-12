namespace :db do
  desc 'Launches the database shell using the values defined in config/database.yml'
  task :shell => :environment do
    config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
    command = ""

    case config['adapter']
    when 'mysql'
      command << "mysql "
      command << "--host=#{config['host'] || 'localhost'} "
      command << "--port=#{config['port'] || 3306} "
      command << "--user=#{config['username'] || 'root'} "
      command << "--password=#{config['password'] || ''} "
      command << config['database']
    when 'postgresql'
      puts 'You should consider switching to MySQL or get off your butt and submit a patch'    
    else
      command << "echo Unsupported database adapter: #{config['adapter']}"
    end

    system command
  end
end