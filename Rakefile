require File.expand_path('../config/application', __FILE__)
Gemcutter::Application.load_tasks

desc "Run all tests and features"
task :default => [:test, :cucumber]

desc "Run daily at 00:00 UTC"
task :cron => %w[gemcutter:downloads:rollover gemcutter:store_legacy_index]
