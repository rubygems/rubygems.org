$:.unshift File.join(File.dirname(__FILE__), '..')

require 'rubygems'
require 'spec'
require 'gemcutter'
require 'sinatra/test/rspec'
require 'rr'
require 'webrat'

Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end
