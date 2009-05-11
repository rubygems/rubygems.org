$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'gemcutter'
require 'rack/test'
require 'spec/expectations'
require 'webrat'

TEST_DIR = File.join('/', 'tmp', 'jekyll')

Webrat.configure do |config|
  config.mode = :sinatra
end

World do
  def app
    @app = Rack::Builder.new do
      run Sinatra::Application.new
    end
  end
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers
end

