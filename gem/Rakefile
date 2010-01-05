require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_command_test.rb']
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gemcutter"
    gem.version = "0.3.0"
    gem.summary = "Commands to interact with gemcutter.org"
    gem.description = "Adds several commands to RubyGems for managing gems and more on Gemcutter.org."
    gem.email = "nick@quaran.to"
    gem.homepage = "http://gemcutter.org"
    gem.authors = ["Nick Quaranto"]
    gem.files = FileList["lib/rubygems_plugin.rb",
                         "lib/commands/*",
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
    gem.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if gem.respond_to? :required_rubygems_version=
    gem.post_install_message = <<MESSAGE

========================================================================

           Thanks for installing Gemcutter! You can now run:

    gem push          publish your gems for the world to use and enjoy
    gem owner         allow/disallow others to push to your gems
    gem webhook       register urls to be pinged when gems are pushed

========================================================================

MESSAGE
  end
  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
