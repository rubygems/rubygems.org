# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gemcutter}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Quaranto"]
  s.date = %q{2009-05-11}
  s.email = %q{nick@quaran.to}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    "README.textile",
    "Rakefile",
    "lib/gemcutter.rb",
    "lib/gemcutter/app.rb",
    "lib/gemcutter/helper.rb",
    "lib/gemcutter/public/css/960.css",
    "lib/gemcutter/public/css/reset.css",
    "lib/gemcutter/public/css/style.css",
    "lib/gemcutter/public/css/text.css",
    "lib/gemcutter/public/favicon.ico",
    "lib/gemcutter/public/gemcutter.jpg",
    "lib/gemcutter/views/gems.haml",
    "lib/gemcutter/views/index.haml",
    "lib/gemcutter/views/layout.haml",
    "lib/rubygems_plugin.rb",
    "lib/server/latest_specs.4.8",
    "lib/server/latest_specs.4.8.gz",
    "lib/server/prerelease_specs.4.8",
    "lib/server/prerelease_specs.4.8.gz",
    "lib/server/specs.4.8",
    "lib/server/specs.4.8.gz",
    "spec/api_spec.rb",
    "spec/gem_spec.rb",
    "spec/gems/test-0.0.0.gem",
    "spec/gems/test-0.0.0.gem_up",
    "spec/gems/test-1.0.0.gem",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/qrush/gemcutter}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Simple and kickass gem hosting}
  s.test_files = [
    "spec/api_spec.rb",
    "spec/gem_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
