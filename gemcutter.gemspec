# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gemcutter}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Quaranto"]
  s.date = %q{2009-06-02}
  s.email = %q{nick@quaran.to}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    "lib/commands/downgrade.rb",
     "lib/commands/push.rb",
     "lib/commands/upgrade.rb",
     "lib/rubygems_plugin.rb"
  ]
  s.homepage = %q{http://github.com/qrush/gemcutter}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{gemcutter}
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Kickass gem hosting}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
