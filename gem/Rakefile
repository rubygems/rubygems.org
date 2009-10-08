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
    gem.summary = "Commands to interact with gemcutter.org"
    gem.description = "Adds several commands for using gemcutter.org, such as pushing new gems, migrating gems from RubyForge, and more."
    gem.email = "nick@quaran.to"
    gem.homepage = "http://github.com/qrush/gemcutter"
    gem.authors = ["Nick Quaranto"]
    gem.files = FileList["lib/rubygems_plugin.rb", "lib/commands/*"]
    gem.test_files = FileList["test/command_helper.rb", "test/commands/*"]
    gem.rubyforge_project = "gemcutter"
    gem.add_dependency('json_pure')
    gem.add_dependency('net-scp')
    gem.post_install_message = <<MESSAGE

========================================================================

           Thanks for installing Gemcutter! You can now run:

    gem tumble        use Gemcutter as your primary RubyGem source
    gem push          publish your gems for the world to use and enjoy
    gem migrate       take over your gem from RubyForge on Gemcutter
    gem owner         allow/disallow others to push to your gems

 Make sure you're running at least RubyGems 1.3.3 to use these plugins.

========================================================================

MESSAGE
  end
  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
