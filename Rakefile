require 'rake'
require 'rake/testtask'
require 'spec/rake/spectask'

desc 'Default: run the specs.'
task :default => :spec

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--format', 'progress', '--color']
end
