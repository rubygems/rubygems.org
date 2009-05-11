$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'gemcutter'
require 'rack/test'
require 'spec/expectations'
require 'webrat'
require 'webrat/sinatra'
require 'rubygems/gem_runner'

TEST_DIR = File.join('/', 'tmp', 'gemcutter')
Sinatra::Application.app_file = File.join(File.dirname(__FILE__), '..', '..', 'lib', 'gemcutter')
require 'haml'

Gemcutter::App.set :environment, :development

Webrat.configure do |config|
  config.mode = :sinatra
end

World do
  def app
    @app = Rack::Builder.new do
      run Gemcutter::App.new
    end
  end
  include Rack::Test::Methods
end
World(Webrat::Methods)
World(Webrat::Matchers)


