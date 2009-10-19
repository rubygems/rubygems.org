# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{redgreen}
  s.version = "1.2.2"

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Wanstrath and Pat Eyler"]
  s.autorequire = %q{redgreen}
  s.cert_chain = nil
  s.date = %q{2007-04-17}
  s.default_executable = %q{rg}
  s.description = %q{redgreen is an expanded version of Pat Eyler's RedGreen.  It will install a 'rg' file in your bin directory.  Use that as you would use 'ruby' when running a test.}
  s.email = ["chris@ozmm.org", "pat.eyler@gmail.com"]
  s.executables = ["rg"]
  s.files = ["README", "bin/rg", "lib/redgreen", "lib/redgreen.rb", "lib/redgreen/autotest.rb", "test/test_fake.rb"]
  s.homepage = %q{http://errtheblog.com/post/15, http://on-ruby.blogspot.com/}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{redgreen is an expanded version of Pat Eyler's RedGreen}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 1

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
