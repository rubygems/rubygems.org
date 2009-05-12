$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')

require 'gemcutter'
app_file = File.join(File.dirname(__FILE__), *%w[.. .. lib gemcutter app.rb])
require app_file
# Force the application name because polyglot breaks the auto-detection logic.
Sinatra::Application.app_file = app_file

require 'spec/expectations'
require 'webrat'
require 'rack/test'

Webrat.configure do |config|
  config.mode = :sinatra
end

World{Webrat::SinatraSession.new}
World(Webrat::Matchers, Webrat::HaveTagMatcher)
