ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'rack/test'
require 'rr'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

class Test::Unit::TestCase
  include Rack::Test::Methods
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)
end

def gem_file(name)
  ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), 'gems', name), 'application/octet-stream', :binary)
end

def regenerate_index
  FileUtils.rm_rf Dir[
    "server/cache/*",
    "server/*specs*",
    "server/quick",
    "server/specifications/*",
    "server/source_index"]
  Gemcutter.indexer.generate_index
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
