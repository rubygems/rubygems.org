require 'rake'
require 'rake/testtask'
require 'spec/rake/spectask'

desc 'Run the specs and features'
task :default => [:spec, :features]

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--format', 'progress', '--color', '--backtrace']
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format pretty"
  end
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gemcutter"
    gem.summary = "Simple and kickass gem hosting"
    gem.email = "nick@quaran.to"
    gem.homepage = "http://github.com/qrush/gemcutter"
    gem.authors = ["Nick Quaranto"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
