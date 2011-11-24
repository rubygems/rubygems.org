namespace :bluepill do
  set(:bluepill_options) { "--no-privileged -c /tmp/bluepill" }

  desc "Stop processes that bluepill is monitoring and quit bluepill"
  task :quit, :roles => [:app] do
    "bluepill stop #{bluepill_options}; true"
    "bluepill quit #{bluepill_options}; true"
  end

  desc "Load bluepill configuration and start it"
  task :start, :roles => [:app] do
    "bluepill load #{release_path}/config/pills/#{rails_env}.rb #{bluepill_options}"
  end

  desc "Prints bluepills monitored processes statuses"
  task :status, :roles => [:app] do
    "bluepill status #{bluepill_options}"
  end
end

