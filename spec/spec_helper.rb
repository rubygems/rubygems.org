$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

app_file = File.join(File.dirname(__FILE__), *%w[.. app app.rb])
require app_file
Sinatra::Application.app_file = app_file

require 'spec'
require 'spec/interop/test'
require 'sinatra/test'
require 'rack/test'
require 'fakeweb'

require 'rr'
require 'webrat'

set :environment, :test
FakeWeb.allow_net_connect = false
Test::Unit::TestCase.send :include, Rack::Test::Methods
Test::Unit::TestCase.send :include, Webrat::Matchers
Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end

def gem_file(name)
  Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__), 'gems', name), 'application/octet-stream', :binary)
end

def app
  Gem::App.new
end

def regenerate_index
  FileUtils.rm_rf Dir["server/cache/*", "server/*specs*", "server/quick", "server/specifications/*"]
  Gem::Cutter.indexer.generate_index
end
