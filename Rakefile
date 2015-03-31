require File.expand_path('../config/application', __FILE__)
Gemcutter::Application.load_tasks

desc "Run weekly at 00:00 UTC"
task :weekly_cron => %w[gemcutter:rubygems:update_download_counts]

task :gen_erd do
  `bundle exec rake erd filetype=svg filename=doc/erd orientation=vertical title="RubyGems.org domain model"`
end
