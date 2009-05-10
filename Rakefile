require 'rake'
require 'rake/testtask'
require 'spec/rake/spectask'

desc 'Default: run the specs.'
task :default => :spec

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--format', 'progress', '--color', '--backtrace']
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
