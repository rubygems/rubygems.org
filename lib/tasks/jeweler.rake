begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gemcutter"
    gem.summary = "Awesome gem hosting"
    gem.email = "nick@quaran.to"
    gem.homepage = "http://github.com/qrush/gemcutter"
    gem.authors = ["Nick Quaranto"]
    gem.files = FileList["lib/rubygems_plugin.rb", "lib/commands/*"]
    gem.test_files = []
    gem.rubyforge_project = "gemcutter"
    gem.post_install_message = <<MESSAGE

=======================================================================
Thanks for installing Gemcutter! To get started, please run: gem tumble
=======================================================================

MESSAGE
  end
  Jeweler::RubyforgeTasks.new

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end
