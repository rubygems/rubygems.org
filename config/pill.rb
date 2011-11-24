REE_PATH = "/opt/ruby-enterprise-1.8.7-2010.02/bin"

Bluepill.application("gemcutter") do |app|
  app.process("delayed_job") do |process|
    process.working_dir = "#{RELEASE_PATH}/current"

    process.start_grace_time    = 10.seconds
    process.stop_grace_time     = 10.seconds
    process.restart_grace_time  = 10.seconds

    process.start_command = "RAILS_ENV=#{RAILS_ENV} script/delayed_job start"
    process.stop_command  = "RAILS_ENV=#{RAILS_ENV} script/delayed_job stop"

    process.pid_file = "#{RELEASE_PATH}/shared/pids/delayed_job.pid"

    process.uid = process.gid = "rubycentral"
    process.supplementary_groups = ['rvm']
  end
end
