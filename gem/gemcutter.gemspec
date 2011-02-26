Gem::Specification.new do |s|
  s.name = %q{gemcutter}
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Quaranto"]
  s.date = %q{2011-02-26}
  s.description = %q{Adds several commands to RubyGems for managing gems and more on RubyGems.org.}
  s.email = %q{nick@quaran.to}
  s.files = [
    "MIT-LICENSE",
    "Rakefile",
    "lib/rubygems/commands/migrate_command.rb",
    "lib/rubygems/commands/tumble_command.rb",
    "lib/rubygems/commands/webhook_command.rb",
    "lib/rubygems/commands/yank_command.rb",
    "lib/rubygems_plugin.rb",
    "test/helper.rb",
    "test/webhook_command_test.rb",
    "test/yank_command_test.rb"
  ]
  s.homepage = %q{http://rubygems.org}
  s.post_install_message = %q{
========================================================================

           Thanks for installing Gemcutter! You can now run:

  gem push        merged into RubyGems 1.3.6
  gem owner       merged into RubyGems 1.3.6
  gem webhook     register urls to be pinged when gems are pushed
  gem yank        remove a specific version of a gem from RubyGems.org

========================================================================

}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Commands to interact with RubyGems.org}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
  end
end
