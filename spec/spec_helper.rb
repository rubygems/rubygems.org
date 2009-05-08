$:.unshift File.join(File.dirname(__FILE__), '..')

require 'spec'
require 'gemcutter'

require 'spec/interop/test'
require 'sinatra/test'
require 'rack/test'

require 'rr'
require 'webrat'

set :environment, :test
Test::Unit::TestCase.send :include, Sinatra::Test

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end
