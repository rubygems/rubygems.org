require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

desc "Run all tests and features"
task :default => [:test, :cucumber]

desc "Run daily at 00:00 UTC"
task :cron => %w[gemcutter:downloads:rollover gemcutter:store_legacy_index]
