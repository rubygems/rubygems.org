# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ginger}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pat Allan"]
  s.date = %q{2008-10-11}
  s.default_executable = %q{ginger}
  s.description = %q{Run specs/tests multiple times through different gem versions.}
  s.email = %q{pat@freelancing-gods.com}
  s.executables = ["ginger"]
  s.files = ["lib/ginger/configuration.rb", "lib/ginger/kernel.rb", "lib/ginger/scenario.rb", "lib/ginger.rb", "LICENCE", "README.textile", "spec/ginger/configuration_spec.rb", "spec/ginger/kernel_spec.rb", "spec/ginger/scenario_spec.rb", "spec/ginger_spec.rb", "bin/ginger"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/freelancing_god/ginger/tree}
  s.rdoc_options = ["--title", "Ginger", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ginger}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{Run specs/tests multiple times through different gem versions.}
  s.test_files = ["spec/ginger/configuration_spec.rb", "spec/ginger/kernel_spec.rb", "spec/ginger/scenario_spec.rb", "spec/ginger_spec.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
