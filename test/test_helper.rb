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
  Cutter.indexer.generate_index
end
