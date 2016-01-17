ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)

require 'rails/test_help'
require 'mocha/mini_test'
require 'bourne'
require 'capybara'
require 'capybara/rails'
require 'factory_girl_rails'
require 'clearance/test_unit'
require 'shoulda'
require 'helpers/gem_helpers'
require 'multi_json'
require 'rack/test'

RubygemFs.mock!

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  include GemHelpers

  def setup
    Redis.current.flushdb
  end

  def page
    Capybara::Node::Simple.new(@response.body)
  end

  def requires_toxiproxy
    skip("Toxiproxy is not running, but was required for this test.") unless Toxiproxy.running?
  end

  def assert_changed(object, attribute)
    original = object.send(attribute)
    yield if block_given?
    latest = object.reload.send(attribute)
    assert_not_equal original, latest,
      "Expected #{object.class} #{attribute} to change but still #{latest}"
  end
end

class ActionDispatch::IntegrationTest
  setup { host! Gemcutter::HOST }
end
Capybara.app_host = "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
end
