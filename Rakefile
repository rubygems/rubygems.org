require File.expand_path('../config/application', __FILE__)
Gemcutter::Application.load_tasks

desc "Run all tests and features"
task :default => [:test, :cucumber]

desc "Run weekly at 00:00 UTC"
task :weekly_cron => %w[gemcutter:rubygems:update_download_counts]
