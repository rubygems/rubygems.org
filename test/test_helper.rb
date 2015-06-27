ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)

require 'minitest/autorun'
require 'rails/test_help'
require 'mocha/mini_test'
require 'bourne'
require 'capybara/rails'
require 'clearance/test_unit'
require 'rubygems/package'
require 'shoulda'

require 'helpers/gem_helpers'

I18n.enforce_available_locales = false

RubygemFs.mock!

class MiniTest::Test
  include Rack::Test::Methods
  include FactoryGirl::Syntax::Methods
  include GemHelpers

  def setup
    Redis.current.flushdb
  end

  def page
    Capybara::Node::Simple.new(@response.body)
  end

  def assert_changed(object, attribute, &block)
    original = object.send(attribute)
    yield
    latest = object.reload.send(attribute)
    assert_not_equal original, latest,
      "Expected #{object.class} #{attribute} to change but still #{latest}"
  end
end

class ActionDispatch::IntegrationTest
  setup { host! Gemcutter::HOST }
end
Capybara.app_host = "http://#{Gemcutter::HOST}"

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
end
