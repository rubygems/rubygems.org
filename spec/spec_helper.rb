$:.unshift File.join(File.dirname(__FILE__), '..')
`git clean -d -f -x #{File.join(File.dirname(__FILE__), "..", "server")}`

require 'spec'
require 'gemcutter'

require 'spec/interop/test'
require 'sinatra/test'
require 'rack/test'

require 'rr'
require 'webrat'

set :environment, :test
Test::Unit::TestCase.send :include, Rack::Test::Methods

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end

def gem_file(name)
  Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__), 'gems', name), 'application/octet-stream', :binary)
end

def app
  Sinatra::Application.new
end
