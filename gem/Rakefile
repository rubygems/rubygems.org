require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gemcutter"
    gem.version = "0.5.0.pre"
    gem.summary = "Commands to interact with RubyGems.org"
    gem.description = "Adds several commands to RubyGems for managing gems and more on RubyGems.org."
    gem.email = "nick@quaran.to"
    gem.homepage = "http://rubygems.org"
    gem.authors = ["Nick Quaranto"]
    gem.files = FileList["lib/rubygems_plugin.rb",
                         "lib/gemcutter.rb",
                         "lib/rubygems/commands/*",
                         "test/*_helper.rb",
                         "test/*_test.rb",
                         "MIT-LICENSE",
                         "Rakefile"]
    gem.test_files = []
    gem.executables = []
    gem.add_runtime_dependency('json_pure')
    %w[rake shoulda activesupport webmock rr].each do |dep|
      gem.add_development_dependency(dep)
    end
    gem.post_install_message = <<MESSAGE

========================================================================

           Thanks for installing Gemcutter! You can now run:

  gem push        merged into RubyGems 1.3.6
  gem owner       merged into RubyGems 1.3.6
  gem webhook     register urls to be pinged when gems are pushed
  gem yank        remove a specific version of a gem from RubyGems.org

========================================================================

MESSAGE
  end
  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
