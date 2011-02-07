namespace :bluepill do
  desc "Stop processes that bluepill is monitoring and quit bluepill"
  task :quit, :roles => [:app] do
    sudo "bluepill stop; true"
    sudo "bluepill quit; true"
  end

  desc "Load bluepill configuration and start it"
  task :start, :roles => [:app] do
    sudo "bluepill load #{release_path}/config/pills/#{rails_env}.rb"
  end

  desc "Prints bluepills monitored processes statuses"
  task :status, :roles => [:app] do
    sudo "bluepill status"
  end
end

