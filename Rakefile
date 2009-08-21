require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

namespace :test do
  Rake::TestTask.new(:commands) do |t|
    t.libs << "gem/test"
    t.test_files = FileList['gem/test/*_test.rb']
    t.verbose = true
  end
end


desc "Run all tests and features"
task :default => ['gemcutter:index:create', :test, :features, 'test:commands']

task :cron => ['gemcutter:update']
