# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ddollar-pacecar}
  s.version = "1.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Jankowski"]
  s.date = %q{2009-07-30}
  s.description = %q{Generated scopes for ActiveRecord classes.}
  s.email = %q{mjankowski@thoughtbot.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["init.rb", "lib", "lib/pacecar", "lib/pacecar/associations.rb", "lib/pacecar/boolean.rb", "lib/pacecar/datetime.rb", "lib/pacecar/duration.rb", "lib/pacecar/helpers.rb", "lib/pacecar/limit.rb", "lib/pacecar/order.rb", "lib/pacecar/polymorph.rb", "lib/pacecar/presence.rb", "lib/pacecar/ranking.rb", "lib/pacecar/search.rb", "lib/pacecar/state.rb", "lib/pacecar.rb", "MIT-LICENSE", "README.rdoc"]
  s.homepage = %q{http://github.com/thoughtbot/pacecar}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Pacecar adds named_scope methods to ActiveRecord classes via database column introspection.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
