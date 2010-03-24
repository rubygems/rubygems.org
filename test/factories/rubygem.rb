Factory.sequence(:name) { |n| "RubyGem#{n}" }

Factory.define :rubygem do |rubygem|
  rubygem.name        { Factory.next(:name) }
  rubygem.association :linkset
end

Factory.define :rubygem_with_downloads, :parent => :rubygem do |rubygem|
  rubygem.after_create do |r|
    $redis[Download.key(r)] = r['downloads']
  end
end

def gem_spec(opts = {})
  Gem::Specification.new do |s|
    s.name = %q{test}
    s.version = opts[:version] || "0.0.0"

    s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
    s.authors = ["Joe User"]
    s.date = %q{2009-05-22}
    s.description = %q{This is my awesome gem.}
    s.email = %q{joe@user.com}
    s.files = [
      "README.textile",
      "Rakefile",
      "VERSION.yml",
      "lib/test.rb",
      "test/test_test.rb"
    ]
    s.homepage = %q{http://user.com/test}
  end
end

def gem_file(name = "test-0.0.0.gem")
  File.open(File.join(File.dirname(__FILE__), '..', 'gems', name))
end
