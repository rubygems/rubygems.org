require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the hoptoad_notifier plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Run ginger tests'
task :ginger do
  $LOAD_PATH << File.join(*%w[vendor ginger lib])
  ARGV.clear
  ARGV << 'test'
  load File.join(*%w[vendor ginger bin ginger])
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', 'TESTING.rdoc']
  end
rescue LoadError
end
